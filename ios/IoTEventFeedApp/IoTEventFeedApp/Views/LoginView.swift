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
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(.systemBackground),
                    Color(.secondarySystemBackground).opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/App Title
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 50))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.blue, Color.blue.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        .padding(.top, 40)
                        
                        Text("IoT Event Feed")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Login Form Card
                    VStack(spacing: 20) {
                        // Username Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Username")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            TextField("Enter username", text: $viewModel.username)
                                .textFieldStyle(ModernTextFieldStyle())
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .submitLabel(.next)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            SecureField("Enter password", text: $viewModel.password)
                                .textFieldStyle(ModernTextFieldStyle())
                                .submitLabel(.go)
                                .onSubmit {
                                    Task {
                                        await viewModel.login()
                                    }
                                }
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.red)
                                Text(errorMessage)
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
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
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(
                                Group {
                                    if viewModel.isFormValid {
                                        LinearGradient(
                                            colors: [Color.blue, Color.blue.opacity(0.8)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    } else {
                                        LinearGradient(
                                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.4)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: viewModel.isFormValid ? Color.blue.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
                        }
                        .disabled(!viewModel.isFormValid || viewModel.isLoading)
                        .padding(.top, 4)
                    }
                    .padding(24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    .padding(.horizontal, 24)
                    
                    // Demo Credentials Card
                    VStack(spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundColor(.blue)
                            Text("Demo Credentials")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 8) {
                            CredentialRow(username: "admin", password: "admin123")
                            CredentialRow(username: "user1", password: "password123")
                            CredentialRow(username: "demo", password: "demo123")
                        }
                    }
                    .padding(20)
                    .background(Color(.secondarySystemBackground).opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

private struct ModernTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separator).opacity(0.3), lineWidth: 1)
            )
    }
}

private struct CredentialRow: View {
    let username: String
    let password: String
    
    var body: some View {
        HStack(spacing: 8) {
            Text(username)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text("/")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(password)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

#Preview {
    LoginView()
        .environment(AppSession())
        .environment(\.networkClient, NetworkClient())
}
