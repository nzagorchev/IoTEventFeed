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
