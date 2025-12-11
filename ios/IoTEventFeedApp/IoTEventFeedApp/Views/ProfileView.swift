//
//  ProfileView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(AppSession.self) private var appSession
    @Environment(\.networkClient) private var networkClient
    @Environment(\.modelContext) private var modelContext
    @State private var user: User?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @State private var downloads: [FileDownload] = []
    @Environment(\.fileDownloadService) private var downloadService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Details Section
                    if let user = user {
                        SectionView(title: "Profile Details") {
                            DetailRow(label: "Name", value: user.name)
                            DetailRow(label: "Username", value: user.username)
                            DetailRow(label: "Email", value: user.email)
                            DetailRow(label: "Role", value: user.role.capitalized)
                        }
                    } else if isLoading {
                        ProgressView("Loading profile...")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    
                    // Downloaded Content Section
                    SectionView(title: "Downloaded Files") {
                        if downloads.isEmpty {
                            HStack {
                                VStack(spacing: 12) {
                                    Image(systemName: "tray")
                                        .font(.system(size: 48))
                                        .foregroundColor(.secondary)
                                    Text("No files downloaded")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 24)
                            }
                        } else {
                            ForEach(downloads) { download in
                                DownloadedFileRow(
                                    download: download,
                                    downloadService: downloadService,
                                    onDelete: {
                                        await deleteFile(download)
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await appSession.logout()
                        }
                    }) {
                        Text("Logout")
                    }
                }
            }
            .task {
                await loadProfile()
                loadDownloads()
            }
        }
    }
    
    private func loadDownloads() {
        if let service = downloadService {
            downloads = service.getAllDownloads()
        }
    }
    
    private func loadProfile() async {
        guard case .loggedIn(let loggedInUser) = appSession.state else {
            return
        }
        
        user = loggedInUser
        
        // Optionally fetch fresh profile data from API
        isLoading = true
        do {
            let apiService = APIService(networkClient: networkClient)
            let apiUser = try await apiService.getUserProfile(id: loggedInUser.id, appSession: appSession)
            user = User(from: apiUser)
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    private func deleteFile(_ download: FileDownload) async {
        guard let service = downloadService else { return }
        
        do {
            try service.deleteFile(download)
            // Refresh downloads list
            downloads = service.getAllDownloads()
        } catch {
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
        }
    }
}

struct DownloadedFileRow: View {
    let download: FileDownload
    let downloadService: FileDownloadService?
    let onDelete: () async -> Void
    
    @State private var associatedEvent: Event?
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.filename)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    HStack {
                        if let fileSize = download.fileSize {
                            Text(formatFileSize(fileSize))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text("Downloaded \(formatDate(download.downloadedAt))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    if let service = downloadService,
                       let localURL = service.getLocalFileURL(for: download) {
                        ShareLink(item: localURL) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await onDelete()
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.vertical, 8)
        }
        .padding(.horizontal)
    }
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    ProfileView()
        .environment(AppSession())
        .environment(\.networkClient, NetworkClient())
        .modelContainer(try! ModelContainer(for: User.self, Event.self, FileDownload.self))
}

