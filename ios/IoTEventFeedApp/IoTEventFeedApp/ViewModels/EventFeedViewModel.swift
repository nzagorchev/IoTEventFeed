//
//  EventFeedViewModel.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftUI
import SwiftData

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
        
        let intervalSeconds = Double(Self.pollingInterval) / 1_000_000_000.0
        AppLogger.info("Starting polling for new events - interval: \(String(format: "%.1f", intervalSeconds)) seconds", category: AppLogger.events)
        
        pollingTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: Self.pollingInterval)
                
                guard !Task.isCancelled else { break }
                AppLogger.debug("Polling: checking for new events...", category: AppLogger.events)
                await checkForNewEvents()
            }
        }
    }
    
    // Cancel polling
    func stopPolling() {
        if pollingTask != nil {
            AppLogger.info("Stopping polling for new events", category: AppLogger.events)
            pollingTask?.cancel()
            pollingTask = nil
        }
    }
    
    private func checkForNewEvents() async {
        guard networkMonitor.isConnected,
              let firstTimestamp = firstEventTimestamp else {
            if !networkMonitor.isConnected {
                AppLogger.debug("Polling skipped: offline", category: AppLogger.events)
            }
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
            
            if newEventsCount > 0 {
                AppLogger.info("Polling: new events found - total: \(newEventsCount), critical: \(newCriticalCount)", category: AppLogger.events)
            }
        } catch {
            AppLogger.error("Polling: failed to check for new events - error: \(error.localizedDescription)", category: AppLogger.events)
            // Silent - do not show error for polling
        }
    }
    
    func loadInitialEvents() async {
        guard !isLoading else { return }
        
        // If offline, load from cache only
        guard networkMonitor.isConnected else {
            AppLogger.info("Loading initial events from cache (offline)", category: AppLogger.events)
            loadFromCache()
            return
        }
        
        AppLogger.info("Loading initial events - limit: \(Self.pageSize)", category: AppLogger.events)
        
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
            
            AppLogger.info("Initial events loaded successfully - count: \(newEvents.count), has_more: \(hasMore)", category: AppLogger.events)
            
            // Update first event timestamp for polling
            if let firstEvent = newEvents.first {
                firstEventTimestamp = Int64(firstEvent.timestamp.timeIntervalSince1970 * 1000)
            }
            
            // Start polling after initial load
            startPolling()
        } catch {
            AppLogger.error("Failed to load initial events - error: \(error.localizedDescription)", category: AppLogger.events)
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
            AppLogger.info("Loading more events from cache (offline)", category: AppLogger.events)
            loadMoreFromCache(afterTimestamp: Date(timeIntervalSince1970: TimeInterval(cursor.timestamp) / 1000.0), afterID: cursor.eventID)
            return
        }
        
        AppLogger.info("Loading more events - after_timestamp: \(cursor.timestamp), after_id: \(cursor.eventID)", category: AppLogger.events)
        
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
            
            AppLogger.info("More events loaded successfully - count: \(newEvents.count), has_more: \(hasMore)", category: AppLogger.events)
        } catch {
            AppLogger.error("Failed to load more events - error: \(error.localizedDescription)", category: AppLogger.events)
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
        
        AppLogger.info("Refreshing new events - before_timestamp: \(firstTimestamp), before_id: \(firstEvent.id)", category: AppLogger.events)
        
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
                AppLogger.info("Refresh: no new events found", category: AppLogger.events)
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
            
            AppLogger.info("Refresh: new events updated - count: \(newEvents.count)", category: AppLogger.events)
            
            // Update first event timestamp
            if let firstNewEvent = newEvents.first {
                firstEventTimestamp = Int64(firstNewEvent.timestamp.timeIntervalSince1970 * 1000)
            }
            
            // Clear new events count
            newEventsCount = 0
            newCriticalCount = 0
        } catch {
            AppLogger.error("Refresh failed - error: \(error.localizedDescription)", category: AppLogger.events)
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

