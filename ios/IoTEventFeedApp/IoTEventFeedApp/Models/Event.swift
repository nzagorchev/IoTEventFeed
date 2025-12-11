//
//  Event.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftData

@Model
final class Event {
    @Attribute(.unique) var id: String
    var deviceID: String
    var deviceName: String
    var type: String
    var severity: String
    var message: String
    var timestamp: Date
    var location: String
    var downloadURL: String?
    
    init(
        id: String,
        deviceID: String,
        deviceName: String,
        type: String,
        severity: String,
        message: String,
        timestamp: Date,
        location: String,
        downloadURL: String? = nil
    ) {
        self.id = id
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.type = type
        self.severity = severity
        self.message = message
        self.timestamp = timestamp
        self.location = location
        self.downloadURL = downloadURL
    }
    
    convenience init(from apiEvent: APIEvent) {
        self.init(
            id: apiEvent.id,
            deviceID: apiEvent.deviceID,
            deviceName: apiEvent.deviceName,
            type: apiEvent.type,
            severity: apiEvent.severity,
            message: apiEvent.message,
            timestamp: apiEvent.timestamp,
            location: apiEvent.location,
            downloadURL: apiEvent.downloadURL
        )
    }
}

// API Response Models
struct APIEvent: Codable {
    let id: String
    let deviceID: String
    let deviceName: String
    let type: String
    let severity: String
    let message: String
    let timestamp: Date
    let location: String
    let downloadURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case deviceID = "device_id"
        case deviceName = "device_name"
        case type
        case severity
        case message
        case timestamp
        case location
        case downloadURL = "download_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        deviceID = try container.decode(String.self, forKey: .deviceID)
        deviceName = try container.decode(String.self, forKey: .deviceName)
        type = try container.decode(String.self, forKey: .type)
        severity = try container.decode(String.self, forKey: .severity)
        message = try container.decode(String.self, forKey: .message)
        location = try container.decode(String.self, forKey: .location)
        downloadURL = try container.decodeIfPresent(String.self, forKey: .downloadURL)
        
        // Decode timestamp as Unix milliseconds
        let timestampMs = try container.decode(Int64.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: TimeInterval(timestampMs) / 1000.0)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(deviceID, forKey: .deviceID)
        try container.encode(deviceName, forKey: .deviceName)
        try container.encode(type, forKey: .type)
        try container.encode(severity, forKey: .severity)
        try container.encode(message, forKey: .message)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(downloadURL, forKey: .downloadURL)
        
        // Encode timestamp as Unix milliseconds
        let timestampMs = Int64(timestamp.timeIntervalSince1970 * 1000)
        try container.encode(timestampMs, forKey: .timestamp)
    }
}

struct EventListResponse: Codable {
    let events: [APIEvent]
    let hasNext: Bool
    let nextCursor: Cursor?
    
    enum CodingKeys: String, CodingKey {
        case events
        case hasNext = "has_next"
        case nextCursor = "next_cursor"
    }
}

struct Cursor: Codable {
    let timestamp: Int64 // Unix milliseconds
    let eventID: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case eventID = "event_id"
    }
}

