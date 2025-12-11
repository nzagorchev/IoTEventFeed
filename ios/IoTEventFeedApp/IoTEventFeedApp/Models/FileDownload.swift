//
//  FileDownload.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftData

@Model
final class FileDownload {
    @Attribute(.unique) var id: String
    var eventID: String
    var downloadURL: String
    var filename: String
    var localFilename: String
    var fileSize: Int64?
    var downloadedAt: Date
    var eventTimestamp: Date
    
    init(
        id: String,
        eventID: String,
        downloadURL: String,
        filename: String,
        localFilename: String,
        fileSize: Int64? = nil,
        downloadedAt: Date = Date(),
        eventTimestamp: Date
    ) {
        self.id = id
        self.eventID = eventID
        self.downloadURL = downloadURL
        self.filename = filename
        self.localFilename = localFilename
        self.fileSize = fileSize
        self.downloadedAt = downloadedAt
        self.eventTimestamp = eventTimestamp
    }
}

