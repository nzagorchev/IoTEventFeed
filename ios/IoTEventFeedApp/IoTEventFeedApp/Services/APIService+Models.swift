//
//  APIService+Models.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 11.12.25.
//

import Foundation

// MARK: - Error

struct APIErrorResponse: Codable {
    let error: String
    let message: String?
    let code: Int
}

// MARK: - User

struct APIUser: Codable {
    let id: String
    let username: String
    let email: String
    let name: String
    let role: String
}

// MARK: - Login

struct LoginRequest: Codable {
    let username: String
    let password: String
}

struct LoginResponse: Codable {
    let token: String
    let user: APIUser
}

// MARK: - Event

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

// MARK: - Events

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

// MARK: - Cursor

struct Cursor: Codable {
    let timestamp: Int64 // Unix milliseconds
    let eventID: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case eventID = "event_id"
    }
}

// MARK: - New Events Count
struct NewEventsCountResponse: Codable {
    let totalCount: Int
    let criticalCount: Int
    
    enum CodingKeys: String, CodingKey {
        case totalCount = "total_count"
        case criticalCount = "critical_count"
    }
}

