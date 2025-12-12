//
//  FileDownloadView.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 11.12.25.
//

import SwiftUI

struct FileDownloadView: View {
    let event: Event
    let downloadURL: String
    
    // If this view should show the error
    // Set to false if error will be shown by a parent view
    var showError = true
    
    @Binding var errorMessage: String?
    
    @Environment(\.fileDownloadService) private var downloadService
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    @State private var fileDownload: FileDownload?
    @State private var isDownloading = false
    @State private var downloadProgress: Double?
    @State private var showDeleteConfirmation = false
    @State private var downloadCancelled = false
    @State private var showFileContent = false
    @State private var fileURLToShow: URL?
    
    var body: some View {
        VStack(spacing: 12) {
            if let download = fileDownload {
                downloadedFileView(download)
            } else if isDownloading {
                downloadingView
            } else {
                downloadButtonView
            }
            
            if showError, let message = errorMessage {
                errorView(message)
            }
        }
        .task {
            await checkDownloadStatus()
        }
        .onChange(of: currentProgress){ old, new in
            downloadProgress = new
        }
        .alert("Delete File", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteFile()
                }
            }
        } message: {
            Text("Are you sure you want to delete this file? This action cannot be undone.")
        }
    }
    
    // MARK: - Downloaded File View
    
    private func downloadedFileView(_ download: FileDownload) -> some View {
        Button(action: {
            if let service = downloadService,
               let localURL = service.getLocalFileURL(for: download) {
                fileURLToShow = localURL
                showFileContent = true
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "doc.fill")
                    .font(.title2)
                    .foregroundColor(.green)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(download.filename)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    HStack(spacing: 8) {
                        if let fileSize = download.fileSize {
                            Text(formatFileSize(fileSize))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(formatDate(download.downloadedAt))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 16) {
                    if let service = downloadService,
                       let localURL = service.getLocalFileURL(for: download) {
                        ShareLink(item: localURL) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    Button(action: {
                        showDeleteConfirmation = true
                    }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundColor(.red)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(12)
            .background(Color.green.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showFileContent) { [fileURLToShow] in
            if let url = fileURLToShow {
                FileContentView(fileURL: url, filename: download.filename)
            }
        }
    }
    
    // MARK: - Downloading View
    
    private var downloadingView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Downloading...")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let progress = downloadProgress {
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    cancelDownload()
                }) {
                    Text("Cancel")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            if let progress = downloadProgress {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle())
            }
        }
        .padding(12)
        .background(Color.blue.opacity(0.05))
        .cornerRadius(8)
    }
    
    // MARK: - Download Button View
    
    private var downloadButtonView: some View {
        Button(action: {
            Task {
                await downloadFile()
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Download Log File")
                        .font(.body)
                        .foregroundColor(.blue)
                    
                    if !networkMonitor.isConnected {
                        Text("No internet connection")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                Image(systemName: "arrow.down")
                    .foregroundColor(.blue)
            }
            .padding(12)
            .background(Color.blue.opacity(0.05))
            .cornerRadius(8)
        }
        .disabled(!networkMonitor.isConnected)
        .opacity(networkMonitor.isConnected ? 1.0 : 0.6)
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.red)
            
            Spacer()
            
            Button(action: {
                errorMessage = nil
            }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red.opacity(0.6))
            }
        }
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(6)
    }
    
    // MARK: - Actions
    
    private func checkDownloadStatus() async {
        guard let service = downloadService else { return }
        
        fileDownload = service.getFileDownload(
            for: event.id,
            downloadURL: downloadURL
        )
        
        // Check if download is in progress
        let fileID = service.generateFileID(eventID: event.id, downloadURL: downloadURL)
        if fileDownload == nil, let progress = service.downloadProgress[fileID] {
            isDownloading = true
            downloadProgress = progress
        }
    }
    
    var currentProgress: Double {
        if let downloadService = downloadService {
            let fileID = downloadService.generateFileID(eventID: event.id, downloadURL: downloadURL)
            return downloadService.downloadProgress[fileID] ?? 0
        }
        return 0
    }
    
    private func downloadFile() async {
        guard let service = downloadService,
              networkMonitor.isConnected else {
            errorMessage = "No internet connection"
            return
        }
        
        isDownloading = true
        errorMessage = nil
        
        do {
            try await service.downloadFile(
                eventID: event.id,
                downloadURL: downloadURL,
                eventTimestamp: event.timestamp
            )
            
            // Refresh download status
            await checkDownloadStatus()
            isDownloading = false
        } catch {
            isDownloading = false
            
            if Task.isCancelled || (downloadCancelled && error is CancellationError ){
                errorMessage = "Download cancelled"
                downloadCancelled = false
            } else {
                errorMessage = "Download failed: \(error.localizedDescription)"
            }
        }
    }
    
    private func deleteFile() async {
        guard let service = downloadService,
              let download = fileDownload else {
            return
        }
        
        do {
            try service.deleteFile(download)
            fileDownload = nil
            errorMessage = nil
        } catch {
            errorMessage = "Failed to delete file: \(error.localizedDescription)"
        }
    }
    
    private func cancelDownload() {
        guard let service = downloadService else { return }
        service.cancelDownload(for: event.id, downloadURL: downloadURL)
        isDownloading = false
        downloadProgress = nil
        errorMessage = "Download cancelled"
        downloadCancelled = true
    }
    
    // MARK: - Formatters
    
    private func formatFileSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

