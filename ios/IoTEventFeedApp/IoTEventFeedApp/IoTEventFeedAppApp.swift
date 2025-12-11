//
//  IoTEventFeedAppApp.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI
import SwiftData

@main
struct IoTEventFeedAppApp: App {
    let container: ModelContainer
    
    init() {
        // Configure SwiftData schema
        let schema = Schema([
            User.self,
            Event.self
        ])
        
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .modelContainer(container)
        }
    }
}
