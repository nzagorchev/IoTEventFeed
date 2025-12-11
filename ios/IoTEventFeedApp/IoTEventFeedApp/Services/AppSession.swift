//
//  AppSession.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftData
import Observation

enum SessionState {
    case loggedOut
    case loggedIn(User)
}

@MainActor
@Observable
final class AppSession {
    var state: SessionState = .loggedOut
    private(set) var token: String?
    
    private let keychain = KeychainService.shared
    private let tokenKey = "auth_token"
    private let userIDKey = "user_id"
    private var modelContext: ModelContext?
    
    init() {
        loadTokenFromKeychain()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // If we have a token but no user loaded, try to load user from SwiftData
        if token != nil, case .loggedOut = state {
            if let userID = try? keychain.get(forKey: userIDKey) {
                loadUserFromSwiftData(userID: userID)
            }
        } else if case .loggedIn(let user) = state {
            // Refresh user data from SwiftData
            loadUserFromSwiftData(userID: user.id)
        }
    }
    
    func setLoggedIn(token: String, user: User) throws {
        // Save token securely to Keychain
        try keychain.saveToken(token, forKey: tokenKey)
        try keychain.save(user.id, forKey: userIDKey)
        
        // Create and save user to SwiftData
        if let context = modelContext {
            context.insert(user)
            try? context.save()
        }
        
        self.token = token
        self.state = .loggedIn(user)
    }
    
    func logout() async {
        guard case .loggedIn = state else { return }
        
        try? keychain.deleteToken(forKey: tokenKey)
        try? keychain.delete(forKey: userIDKey)
        
        token = nil
        state = .loggedOut
    }
    
    private func loadTokenFromKeychain() {
        do {
            let token = try keychain.getToken(forKey: tokenKey)
            self.token = token
        } catch {
            // No token found - user needs to login
            state = .loggedOut
        }
    }
    
    private func loadUserFromSwiftData(userID: String) {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate<User> { $0.id == userID }
        )
        
        if let users = try? context.fetch(descriptor), let user = users.first {
            state = .loggedIn(user)
        } else {
            // User not found in SwiftData, but we have a token
            // This should not happen, handle gracefully
            state = .loggedOut
            token = nil
        }
    }
}
