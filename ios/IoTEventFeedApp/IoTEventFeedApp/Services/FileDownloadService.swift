//
//  FileDownloadService.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftData
import Observation
import SwiftUICore

@Observable
final class FileDownloadService {
    let modelContainer: ModelContainer
    private let networkClient: NetworkClient
    private let appSession: AppSession
    
    private let documentsDirectory: URL
    
    // Download progress tracking: [fileID: progress]
    @MainActor
    var downloadProgress: [String: Double] = [:]
    
    // Ongoing download tasks
    private var ongoingTasks: [String: Task<Void, Error>] = [:]
    
    init(modelContainer: ModelContainer, networkClient: NetworkClient, appSession: AppSession) {
        self.modelContainer = modelContainer
        self.networkClient = networkClient
        self.appSession = appSession
        
        // Get documents directory
        documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        // Create downloads subdirectory if it doesn't exist
        let downloadsDirectory = documentsDirectory.appendingPathComponent("Downloads", isDirectory: true)
        if !FileManager.default.fileExists(atPath: downloadsDirectory.path) {
            try? FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
        }
    }
    
    @MainActor
    func isFileDownloaded(for eventID: String, downloadURL: String) -> Bool {
        let fileID = generateFileID(eventID: eventID, downloadURL: downloadURL)
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FileDownload>(
            predicate: #Predicate<FileDownload> { $0.id == fileID }
        )
        
        if let downloads = try? context.fetch(descriptor), !downloads.isEmpty {
            // Check if file still exists on disk
            let download = downloads[0]
            return FileManager.default.fileExists(atPath: getFilePath(for: download.localFilename))
        }
        return false
    }
    
    @MainActor
    func getFileDownload(for eventID: String, downloadURL: String) -> FileDownload? {
        let fileID = generateFileID(eventID: eventID, downloadURL: downloadURL)
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FileDownload>(
            predicate: #Predicate<FileDownload> { $0.id == fileID }
        )
        
        if let downloads = try? context.fetch(descriptor), let download = downloads.first {
            // Verify file still exists
            if FileManager.default.fileExists(atPath: getFilePath(for: download.localFilename)) {
                return download
            } else {
                // File was deleted, remove from database
                context.delete(download)
                try? context.save()
            }
        }
        return nil
    }
    
    @MainActor
    private func getFilePath(for localName: String) -> String {
        return documentsDirectory
            .appendingPathComponent("Downloads", isDirectory: true)
            .appendingPathComponent(localName)
            .path
    }
    
    @MainActor
    func getAllDownloads() -> [FileDownload] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<FileDownload>(
            sortBy: [SortDescriptor(\.downloadedAt, order: .reverse)]
        )
        
        if let downloads = try? context.fetch(descriptor) {
            // Filter out files that no longer exist and clean up
            let validDownloads = downloads.filter { FileManager.default.fileExists(atPath: getFilePath(for: $0.localFilename)) }
            
            // Clean up invalid entries
            let invalidDownloads = downloads.filter { !FileManager.default.fileExists(atPath: getFilePath(for: $0.localFilename)) }
            for invalid in invalidDownloads {
                context.delete(invalid)
            }
            if !invalidDownloads.isEmpty {
                try? context.save()
            }
            
            return validDownloads
        }
        return []
    }
    
    func downloadFile(
        eventID: String,
        downloadURL: String,
        eventTimestamp: Date
    ) async throws {
        let fileID = generateFileID(eventID: eventID, downloadURL: downloadURL)

        // Check if file is already downloaded
        let isDownloaded = await MainActor.run {
            isFileDownloaded(for: eventID, downloadURL: downloadURL)
        }
        
        if isDownloaded {
            return
        }

        // If download already in progress, wait for it
        if let existingTask = ongoingTasks[fileID] {
            return try await existingTask.value
        }

        let newTask = Task {
            try await self.performDownload(
                fileID: fileID,
                eventID: eventID,
                downloadURL: downloadURL,
                eventTimestamp: eventTimestamp
            )
        }

        ongoingTasks[fileID] = newTask

        defer {
            ongoingTasks[fileID] = nil
        }

        try await newTask.value
    }
    
    private func performDownload(
        fileID: String,
        eventID: String,
        downloadURL: String,
        eventTimestamp: Date
    ) async throws {
        guard let url = networkClient.fullURL(for: downloadURL) else {
            throw FileDownloadError.invalidURL
        }
        
        // Determine filename
        let filename = url.lastPathComponent
        let sanitizedName = filename.sanitizedFilename()
        let localFilename = "\(eventID)_\(sanitizedName)"
        let localFilePath = documentsDirectory
            .appendingPathComponent("Downloads", isDirectory: true)
            .appendingPathComponent(localFilename)
            .path
        
        await MainActor.run {
            downloadProgress[fileID] = 0.0
        }
        
        do {
            // Create download task
            var request = URLRequest(url: url)
            let token = await appSession.token
            if let token = token {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Use async bytes for progress tracking
            let (asyncBytes, response) = try await URLSession.shared.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw FileDownloadError.downloadFailed
            }
            
            // Get content length for progress tracking
            let contentLength = httpResponse.value(forHTTPHeaderField: "Content-Length")
                .flatMap { Int64($0) }
            
            // Calculate optimal buffer size
            let writeBufferSize = calculateOptimalBufferSize(contentLength: contentLength)
            let progressUpdateInterval = writeBufferSize
            
            // Create file
            FileManager.default.createFile(atPath: localFilePath, contents: nil, attributes: nil)
            let fileHandle = try FileHandle(forWritingTo: URL(fileURLWithPath: localFilePath))
            defer { try? fileHandle.close() }
            
            var downloadedBytes: Int64 = 0
            var buffer = Data()
            buffer.reserveCapacity(writeBufferSize) // Pre-allocate buffer
            var lastProgressUpdate: Int64 = 0
            
            // Read bytes from async sequence and accumulate in buffer
            for try await byte in asyncBytes {
                buffer.append(byte)
                downloadedBytes += 1
                
                // Write buffer when it reaches optimal size
                if buffer.count >= writeBufferSize {
                    try fileHandle.write(contentsOf: buffer)
                    buffer.removeAll(keepingCapacity: true)
                }
                
                // Throttle progress updates
                if let totalBytes = contentLength, totalBytes > 0 {
                    let bytesSinceLastUpdate = downloadedBytes - lastProgressUpdate
                    if bytesSinceLastUpdate >= progressUpdateInterval {
                        let progress = Double(downloadedBytes) / Double(totalBytes)
                        await MainActor.run {
                            downloadProgress[fileID] = min(progress, 1.0)
                        }
                        lastProgressUpdate = downloadedBytes
                    }
                }
            }
            
            // Write remaining buffer
            if !buffer.isEmpty {
                try fileHandle.write(contentsOf: buffer)
            }
            
            // Final progress update
            await MainActor.run {
                downloadProgress[fileID] = 1.0
            }
            
            // Get file size
            let fileSize = try? FileManager.default.attributesOfItem(atPath: localFilePath)[.size] as? Int64
            
            // Save metadata on main actor to avoid threading issues
            await MainActor.run {
                let context = ModelContext(modelContainer)
                let download = FileDownload(
                    id: fileID,
                    eventID: eventID,
                    downloadURL: downloadURL,
                    filename: filename,
                    localFilename: localFilename,
                    fileSize: fileSize,
                    downloadedAt: Date(),
                    eventTimestamp: eventTimestamp
                )
                
                context.insert(download)
                try? context.save()
                
                // Clear progress
                downloadProgress[fileID] = nil
            }
            
        } catch {
            // Clean up on error
            await MainActor.run {
                downloadProgress[fileID] = nil
            }
            try? FileManager.default.removeItem(atPath: localFilePath)
            throw error
        }
    }
    
    @MainActor
    func deleteFile(_ download: FileDownload) throws {
        let context = ModelContext(modelContainer)
        
        // Delete file from disk
        try? FileManager.default.removeItem(atPath: getFilePath(for: download.localFilename))
        
        // Get the persistent model ID to safely delete
        let downloadID = download.id
        let descriptor = FetchDescriptor<FileDownload>(
            predicate: #Predicate<FileDownload> { $0.id == downloadID }
        )
        
        if let downloads = try? context.fetch(descriptor), let existingDownload = downloads.first {
            context.delete(existingDownload)
            try context.save()
        }
    }
    
    @MainActor
    func getLocalFileURL(for download: FileDownload) -> URL? {
        if FileManager.default.fileExists(atPath: getFilePath(for: download.localFilename)) {
            return URL(fileURLWithPath: download.localFilename)
        }
        return nil
    }
    
    func generateFileID(eventID: String, downloadURL: String) -> String {
        // Use eventID + filename from URL as unique identifier
        let url = URL(string: downloadURL)
        let filename = url?.lastPathComponent ?? downloadURL
        return "\(eventID)_\(filename)"
    }
    
    // Calculates optimal buffer size based on file size
    private func calculateOptimalBufferSize(contentLength: Int64?) -> Int {
        guard let fileSize = contentLength else {
            return 262_144 // 256KB default
        }
        
        switch fileSize {
        case 0..<1_048_576: // < 1MB
            return 65_536 // 64KB
        case 1_048_576..<10_485_760: // 1MB - 10MB
            return 262_144 // 256KB
        default: // > 10MB
            return 524_288 // 512KB
        }
    }
    
    // Cancel an ongoing download
    func cancelDownload(for eventID: String, downloadURL: String) {
        let fileID = generateFileID(eventID: eventID, downloadURL: downloadURL)
        ongoingTasks[fileID]?.cancel()
        ongoingTasks[fileID] = nil
        
        Task { @MainActor in
            downloadProgress[fileID] = nil
        }
    }
}

enum FileDownloadError: LocalizedError {
    case invalidURL
    case downloadFailed
    case fileNotFound
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid download URL"
        case .downloadFailed:
            return "Failed to download file"
        case .fileNotFound:
            return "File not found"
        }
    }
}

extension String {
    func sanitizedFilename() -> String {
        let invalid = CharacterSet(charactersIn: "/\\:*?\"<>|")
        return components(separatedBy: invalid).joined(separator: "_")
    }
}

// Environment key for FileDownloadService
private struct FileDownloadServiceKey: EnvironmentKey {
    static let defaultValue: FileDownloadService? = nil
}

extension EnvironmentValues {
    var fileDownloadService: FileDownloadService? {
        get { self[FileDownloadServiceKey.self] }
        set { self[FileDownloadServiceKey.self] = newValue }
    }
}
