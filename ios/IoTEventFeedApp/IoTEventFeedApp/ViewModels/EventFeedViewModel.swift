//
//  EventFeedViewModel.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftUI
import SwiftData
import os.log

@MainActor
@Observable
final class EventFeedViewModel {
    var events: [Event] = []
    var isLoading: Bool = false
    var isLoadingMore: Bool = false
    var errorMessage: String?
    var hasMore: Bool = true
    var newEventsCount: Int = 0
    var newCriticalCount: Int = 0
    
    private var nextCursor: Cursor?
    private var firstEventTimestamp: Int64? // Timestamp of the first (newest) event
    private var pollingTask: Task<Void, Never>?
    
    private let apiService: APIService
    private let appSession: AppSession
    private let modelContext: ModelContext
    private let networkMonitor: NetworkMonitor
    
    private static let pageSize = 20
    private static let pollingInterval: UInt64 = 30_000_000_000 // 30 seconds
    
    init(apiService: APIService, appSession: AppSession, modelContext: ModelContext, networkMonitor: NetworkMonitor) {
        self.apiService = apiService
        self.appSession = appSession
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor
    }
    
    var isOffline: Bool {
        !networkMonitor.isConnected
    }
    
    // Starts polling if new events are available
    func startPolling() {
        stopPolling()
        
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.pollingInterval)
                
                guard !Task.isCancelled else { break }
                os_log("checking for new events...")
                await checkForNewEvents()
            }
        }
    }
    
    // Cancel polling
    func stopPolling() {
        pollingTask?.cancel()
        pollingTask = nil
    }
    
    private func checkForNewEvents() async {
        guard networkMonitor.isConnected,
              let firstTimestamp = firstEventTimestamp else {
            return
        }
        
        do {
            let countResponse = try await apiService.getNewEventsCount(
                afterTimestamp: firstTimestamp,
                appSession: appSession
            )
            
            // Update state
            newEventsCount = countResponse.totalCount
            newCriticalCount = countResponse.criticalCount
            os_log("new events count: %d, critical count: %d", newEventsCount, newCriticalCount)
        } catch {
            // Silent - do not show error for polling
        }
    }
    
    func loadInitialEvents() async {
        guard !isLoading else { return }
        
        // If offline, load from cache only
        guard networkMonitor.isConnected else {
            loadFromCache()
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Loading initial events gets the newest events
            let response = try await apiService.getEvents(
                limit: Self.pageSize,
                appSession: appSession
            )
            
            // Convert API events to SwiftData events
            let newEvents = response.events.map { Event(from: $0) }
            
            // Save to SwiftData (check for duplicates)
            for event in newEvents {
                insertEventIfNotExists(event)
            }
            try? modelContext.save()
            
            events = newEvents
            hasMore = response.hasNext
            nextCursor = response.nextCursor
            
            os_log("events updated")
            
            // Update first event timestamp for polling
            if let firstEvent = newEvents.first {
                firstEventTimestamp = Int64(firstEvent.timestamp.timeIntervalSince1970 * 1000)
            }
            
            // Start polling after initial load
            startPolling()
        } catch {
            errorMessage = error.localizedDescription
            
            // Try to load from cache if network fails
            loadFromCache()
            
            // Update first event timestamp from cache
            if let firstEvent = events.first {
                firstEventTimestamp = Int64(firstEvent.timestamp.timeIntervalSince1970 * 1000)
            }
        }
        
        isLoading = false
    }
    
    func loadMoreEvents() async {
        guard !isLoadingMore, hasMore, let cursor = nextCursor else { return }
        
        // If offline, try to load from cache
        guard networkMonitor.isConnected else {
            loadMoreFromCache(afterTimestamp: Date(timeIntervalSince1970: TimeInterval(cursor.timestamp) / 1000.0), afterID: cursor.eventID)
            return
        }
        
        isLoadingMore = true
        
        do {
            let response = try await apiService.getEvents(
                afterCursor: cursor,
                appSession: appSession
            )
            
            // Convert API events to SwiftData events
            let newEvents = response.events.map { Event(from: $0) }
            
            // Save to SwiftData (check for duplicates)
            for event in newEvents {
                insertEventIfNotExists(event)
            }
            try? modelContext.save()
            
            events.append(contentsOf: newEvents)
            hasMore = response.hasNext
            nextCursor = response.nextCursor
        } catch {
            // On error, try to load more from cache
            loadMoreFromCache(afterTimestamp: Date(timeIntervalSince1970: TimeInterval(cursor.timestamp) / 1000.0), afterID: cursor.eventID)
        }
        
        isLoadingMore = false
    }
    
    func refreshNewEvents() async {
        guard !isLoading, networkMonitor.isConnected,
              let firstTimestamp = firstEventTimestamp,
              let firstEvent = events.first else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Create cursor from first event (for before_ts - get events newer than this)
        let cursor = Cursor(
            timestamp: firstTimestamp,
            eventID: firstEvent.id
        )
        
        do {
            // Fetch new events using before_ts (newer events)
            let response = try await apiService.getEvents(
                beforeCursor: cursor,
                appSession: appSession
            )
            
            let newEvents = response.events.map { Event(from: $0) }
            
            guard !newEvents.isEmpty else {
                // No new events
                newEventsCount = 0
                newCriticalCount = 0
                isLoading = false
                return
            }
            
            // Save to SwiftData (check for duplicates)
            for event in newEvents {
                insertEventIfNotExists(event)
            }
            try? modelContext.save()
            
            // Determine if there's a gap:
            // If hasNext is false, we fetched all newer events (no gap) - prepend
            // If hasNext is true, there might be a gap or more events - replace to show only new items
            if !response.hasNext {
                // No more events to fetch - no gap, prepend to top
                events = newEvents + events
            } else {
                // There are more events (potential gap) - replace with new events only
                events = newEvents
                hasMore = response.hasNext
                if let nextCursor = response.nextCursor {
                    self.nextCursor = nextCursor
                } else if let lastEvent = newEvents.last {
                    // Create cursor from last event for pagination
                    self.nextCursor = Cursor(
                        timestamp: Int64(lastEvent.timestamp.timeIntervalSince1970 * 1000),
                        eventID: lastEvent.id
                    )
                }
            }
            
            os_log("new events updated")
            
            // Update first event timestamp
            if let firstNewEvent = newEvents.first {
                firstEventTimestamp = Int64(firstNewEvent.timestamp.timeIntervalSince1970 * 1000)
            }
            
            // Clear new events count
            newEventsCount = 0
            newCriticalCount = 0
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func loadFromCache() {
        // Sort by timestamp descending, then by ID descending to match backend
        var descriptor = FetchDescriptor<Event>(
            sortBy: [
                SortDescriptor(\.timestamp, order: .reverse),
                SortDescriptor(\.id, order: .reverse)
            ]
        )
        
        // Fetch count
        var hasMoreEvents: Bool = false
        if let count = try? modelContext.fetchCount(descriptor), count > Self.pageSize {
            hasMoreEvents = true
        }
        
        // Set page size
        descriptor.fetchLimit = Self.pageSize
        
        if let cachedEvents = try? modelContext.fetch(descriptor) {
            events = cachedEvents
            
            // Update first event timestamp from cache
            if let firstEvent = cachedEvents.first {
                firstEventTimestamp = Int64(firstEvent.timestamp.timeIntervalSince1970 * 1000)
            }
            
            // Set cursor for loading more events
            if hasMoreEvents, let lastEvent = cachedEvents.last {
                nextCursor = Cursor(
                    timestamp: Int64(lastEvent.timestamp.timeIntervalSince1970 * 1000),
                    eventID: lastEvent.id
                )
                hasMore = true
            } else {
                setNoMoreEvents()
            }
        }
    }
    
    private func loadMoreFromCache(afterTimestamp: Date, afterID: String) {
        // Sort by timestamp descending, then by ID descending to match backend
        // Filter events older than afterTimestamp, or same timestamp but ID < afterID
        var descriptor = FetchDescriptor<Event>(
            predicate: #Predicate<Event> { event in
                event.timestamp < afterTimestamp ||
                (event.timestamp == afterTimestamp && event.id < afterID)
            },
            sortBy: [
                SortDescriptor(\.timestamp, order: .reverse),
                SortDescriptor(\.id, order: .reverse)
            ]
        )
        
        // Fetch count
        var hasMoreEvents: Bool = false
        if let count = try? modelContext.fetchCount(descriptor), count > Self.pageSize {
            hasMoreEvents = true
        }
        
        // Set page size
        descriptor.fetchLimit = Self.pageSize
        
        if let cachedEvents = try? modelContext.fetch(descriptor) {
            events.append(contentsOf: cachedEvents)
            
            if hasMoreEvents, let lastEvent = cachedEvents.last {
                nextCursor = Cursor(
                    timestamp: Int64(lastEvent.timestamp.timeIntervalSince1970 * 1000),
                    eventID: lastEvent.id
                )
                hasMore = true
            } else {
                setNoMoreEvents()
            }
        }
    }
    
    private func setNoMoreEvents() {
        hasMore = false
        nextCursor = nil
    }
    
    private func insertEventIfNotExists(_ event: Event) {
        // Check if event with this ID already exists
        let id = event.id
        let descriptor = FetchDescriptor<Event>(
            predicate: #Predicate { $0.id == id })
        
        if let existingEvents = try? modelContext.fetch(descriptor), existingEvents.isEmpty {
            modelContext.insert(event)
        }
    }
}

