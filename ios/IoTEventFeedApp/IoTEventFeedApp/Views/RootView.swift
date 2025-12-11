//
//  RootView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    let modelContainer: ModelContainer
    
    @State private var session = AppSession()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.networkClient) private var networkClient
    @State private var downloadService: FileDownloadService? = nil
    
    var body: some View {
        Group {
            switch session.state {
            case .loggedIn:
                TabView {
                    EventFeedView()
                        .tabItem {
                            Label("Events", systemImage: "antenna.radiowaves.left.and.right")
                        }
                    ProfileView()
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                        }
                }
            case .loggedOut:
                LoginView()
            }
        }
        .environment(session)
        .environment(\.networkClient, networkClient)
        .environment(\.fileDownloadService, downloadService)
        .onAppear {
            session.setModelContext(modelContext)
            
            if downloadService == nil {
                downloadService = FileDownloadService(
                    modelContainer: modelContainer,
                    networkClient: networkClient,
                    appSession: session
                )
            }
        }
    }
}

#Preview {
    let schema = Schema([
        User.self,
        Event.self,
        FileDownload.self
    ])
    
    let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
    
    let container = try! ModelContainer(for: schema, configurations: [modelConfiguration])
    
    return RootView(modelContainer: container)
        .modelContainer(container)
}
