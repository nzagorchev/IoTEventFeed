//
//  LoginViewModel.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftUI

@MainActor
@Observable
final class LoginViewModel {
    var username: String = ""
    var password: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
    private let apiService: APIService
    private let appSession: AppSession
    
    init(apiService: APIService, appSession: AppSession) {
        self.apiService = apiService
        self.appSession = appSession
    }
    
    var isFormValid: Bool {
        !username.isEmpty && !password.isEmpty
    }
    
    func login() async {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let loginResponse = try await apiService.login(username: username, password: password)
            
            // Update AppSession with login response
            let user = User(from: loginResponse.user)
            try appSession.setLoggedIn(token: loginResponse.token, user: user)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

