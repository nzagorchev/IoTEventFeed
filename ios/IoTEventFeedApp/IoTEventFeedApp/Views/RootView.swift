//
//  RootView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var session = AppSession()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.networkClient) private var networkClient
    
    var body: some View {
        Group {
            switch session.state {
            case .loggedIn:
                EventFeedView()
            case .loggedOut:
                LoginView()
            }
        }
        .environment(session)
        .environment(\.networkClient, networkClient)
        .onAppear {
            session.setModelContext(modelContext)
        }
    }
}

#Preview {
    RootView()
}
