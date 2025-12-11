//
//  EventDetailView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI

struct EventDetailView: View {
    let event: Event
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @State private var fullEvent: Event?
    @State private var showErrorBanner = false
    @State private var showOfflineBanner = false
    
    @Environment(AppSession.self) private var appSession
    @Environment(\.networkClient) private var networkClient
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var displayEvent: Event {
        fullEvent ?? event
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header with severity
                    HStack {
                        Circle()
                            .fill(getSeverityColor(severity: displayEvent.severity))
                            .frame(width: 16, height: 16)
                        
                        Text(displayEvent.severity.uppercased())
                            .font(.headline)
                            .foregroundColor(getSeverityColor(severity: displayEvent.severity))
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    Divider()
                    
                    SectionView(title: "Device Information") {
                        DetailRow(label: "Device Name", value: displayEvent.deviceName)
                        DetailRow(label: "Device ID", value: displayEvent.deviceID)
                    }
                    
                    SectionView(title: "Event Details") {
                        DetailRow(label: "Type", value: displayEvent.type.replacingOccurrences(of: "_", with: " ").capitalized)
                        DetailRow(label: "Severity", value: displayEvent.severity.capitalized)
                        DetailRow(label: "Message", value: displayEvent.message)
                    }
                    
                    SectionView(title: "Location") {
                        DetailRow(label: "Location", value: displayEvent.location)
                    }
                    
                    SectionView(title: "Timestamp") {
                        DetailRow(label: "Date & Time", value: formattedFullTimestamp)
                        DetailRow(label: "Relative Time", value: formattedRelativeTimestamp)
                    }
                    
                    SectionView(title: "Technical Details") {
                        DetailRow(label: "Event ID", value: displayEvent.id)
                    }
                    
                    if let downloadURLString = displayEvent.downloadURL {
                        SectionView(title: "Attachments") {
                            FileDownloadView(
                                event: event,
                                downloadURL: downloadURLString,
                                showError: false,
                                errorMessage: $errorMessage
                            )
                        }
                        .padding(.bottom, 20)
                        Spacer()
                    }
                    
                    if isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    }
                }
                .padding(.vertical)
            }
            
            // Banners overlay
            VStack(spacing: 8) {
                if showOfflineBanner {
                    OfflineBanner(isPresented: $showOfflineBanner)
                }
                
                if showErrorBanner, let error = errorMessage {
                    ErrorBanner(error, isPresented: $showErrorBanner)
                }
            }
        }
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    Task {
                        await loadFullEvent()
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.accentColor)
                    }
                }
                .disabled(isLoading || !networkMonitor.isConnected)
            }
        }
        .task {
            await loadFullEvent()
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            withAnimation {
                showOfflineBanner = !isConnected
            }
        }
        .onChange(of: errorMessage) { _, errorMessage in
            withAnimation {
                showErrorBanner = errorMessage != nil
            }
        }
        .onAppear {
            showOfflineBanner = !networkMonitor.isConnected
            showErrorBanner = errorMessage != nil
        }
    }
    
    private func loadFullEvent() async {
        guard networkMonitor.isConnected else { return }
        
        isLoading = true
        errorMessage = nil
        
        AppLogger.info("Refresh event details for id: \(event.id)", category: AppLogger.events)
        
        do {
            let apiService = APIService(networkClient: networkClient)
            let apiEvent = try await apiService.getEvent(id: event.id, appSession: appSession)
            fullEvent = Event(from: apiEvent)
        } catch {
            errorMessage = "Failed to load full event details: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    private var formattedFullTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .medium
        return formatter.string(from: displayEvent.timestamp)
    }
    
    private var formattedRelativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: displayEvent.timestamp, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        EventDetailView(event: Event(
            id: "71cae9cc-2bb3-4648-bf28-8c2e08a3265a",
            deviceID: "DEVICE-001",
            deviceName: "Device - Main Entrance",
            type: "facial_authentication",
            severity: "info",
            message: "Facial authentication successful",
            timestamp: Date(),
            location: "Main Entrance, Building A",
            downloadURL: nil
        ))
        .environment(AppSession())
        .environment(\.networkClient, NetworkClient())
        .environment(NetworkMonitor())
    }
}

