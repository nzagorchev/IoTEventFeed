//
//  EventFeedView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI
import SwiftData

struct EventFeedView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.networkClient) private var networkClient
    @Environment(\.modelContext) private var modelContext
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var viewModel: EventFeedViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    EventFeedContentView(viewModel: viewModel, appSession: appSession, networkMonitor: networkMonitor)
                } else {
                    ProgressView("Loading...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .onAppear {
                if viewModel == nil {
                    let apiService = APIService(networkClient: networkClient)
                    viewModel = EventFeedViewModel(
                        apiService: apiService,
                        appSession: appSession,
                        modelContext: modelContext,
                        networkMonitor: networkMonitor
                    )
                }
            }
        }
    }
}

private struct EventFeedContentView: View {
    @Bindable var viewModel: EventFeedViewModel
    let appSession: AppSession
    let networkMonitor: NetworkMonitor
    @State private var showErrorBanner = false
    @State private var showOfflineBanner = false
    @State private var showNewEventsBanner = false
    
    var body: some View {
        ZStack(alignment: .top) {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Loading events...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.events.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No events found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.events) { event in
                                NavigationLink(value: event) {
                                    EventRowView(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            if viewModel.isLoadingMore {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .padding()
                                    Spacer()
                                }
                            } else if viewModel.hasMore {
                                // Placeholder
                                // Appears once view is scrolled to it
                                Color.clear
                                    .frame(height: 1)
                                    .onAppear {
                                        // Only load more if online
                                        if networkMonitor.isConnected {
                                            Task {
                                                await viewModel.loadMoreEvents()
                                            }
                                        }
                                    }
                            } else {
                                // Show no more events at the bottom once all loaded
                                HStack {
                                    Spacer()
                                    Text("No more events to show")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.vertical, 16)
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .refreshable {
                        if networkMonitor.isConnected {
                            await viewModel.refreshNewEvents()
                        }
                    }
                }
            }
            
            // Banners overlay
            VStack(spacing: 8) {
                if showOfflineBanner {
                    OfflineBanner(isPresented: $showOfflineBanner)
                }
                
                if showNewEventsBanner && viewModel.newEventsCount > 0 {
                    NewEventsBannerView(
                        totalCount: viewModel.newEventsCount,
                        criticalCount: viewModel.newCriticalCount,
                        onRefresh: {
                            Task {
                                await viewModel.refreshNewEvents()
                            }
                        },
                        isPresented: $showNewEventsBanner
                    )
                }
                
                if showErrorBanner, let errorMessage = viewModel.errorMessage {
                    ErrorBanner(errorMessage, isPresented: $showErrorBanner)
                }
            }
        }
        .navigationTitle("Event Feed")
        .navigationDestination(for: Event.self) { event in
            EventDetailView(event: event)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: .destructive, action: {
                        Task {
                            await appSession.logout()
                        }
                    }) {
                        Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            if viewModel.events.isEmpty {
                await viewModel.loadInitialEvents()
            } else {
                // Start polling if events are already loaded
                viewModel.startPolling()
            }
        }
        .onDisappear {
            viewModel.stopPolling()
        }
        .onChange(of: networkMonitor.isConnected) { _, isConnected in
            withAnimation {
                showOfflineBanner = !isConnected
            }
        }
        .onChange(of: viewModel.errorMessage) { _, errorMessage in
            withAnimation {
                showErrorBanner = errorMessage != nil
            }
        }
        .onChange(of: viewModel.newEventsCount) { _, count in
            withAnimation {
                showNewEventsBanner = count > 0 && networkMonitor.isConnected
            }
        }
        .onAppear {
            showOfflineBanner = !networkMonitor.isConnected
            showErrorBanner = viewModel.errorMessage != nil
            showNewEventsBanner = viewModel.newEventsCount > 0 && networkMonitor.isConnected
        }
    }
}

#Preview {
    EventFeedView()
        .environment(AppSession())
        .environment(\.networkClient, NetworkClient())
        .environment(NetworkMonitor())
        .modelContainer(try! ModelContainer(for: Event.self))
}
