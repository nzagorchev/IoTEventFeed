//
//  LoginView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI

struct LoginView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.networkClient) private var networkClient
    @State private var viewModel: LoginViewModel?
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    LoginContentView(viewModel: viewModel)
                } else {
                    ProgressView()
                }
            }
            .onAppear {
                if viewModel == nil {
                    let apiService = APIService(networkClient: networkClient)
                    viewModel = LoginViewModel(apiService: apiService, appSession: session)
                }
            }
        }
    }
}

private struct LoginContentView: View {
    @Bindable var viewModel: LoginViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            // Logo/App Title
            VStack(spacing: 8) {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("IoT Event Feed")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 60)
            
            // Login Form
            VStack(spacing: 16) {
                // Username Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Username")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    SecureField("Enter password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.go)
                        .onSubmit {
                            Task {
                                await viewModel.login()
                            }
                        }
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
                // Login Button
                Button(action: {
                    Task {
                        await viewModel.login()
                    }
                }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(viewModel.isFormValid ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!viewModel.isFormValid || viewModel.isLoading)
                .padding(.top, 8)
            }
            .padding(.horizontal, 32)
            
            // Demo Credentials Hint
            VStack(spacing: 8) {
                Text("Demo Credentials")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 4) {
                    Text("admin / admin123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("user1 / password123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("demo / demo123")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 20)
            
            Spacer()
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    LoginView()
        .environment(AppSession())
        .environment(\.networkClient, NetworkClient())
}
