//
//  Logger.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import os.log

struct AppLogger {
    private static let subsystem = "com.ioteventfeed.app"
    
    // MARK: - Log Categories
    
    static let auth = OSLog(subsystem: subsystem, category: "auth")
    static let events = OSLog(subsystem: subsystem, category: "events")
    static let files = OSLog(subsystem: subsystem, category: "files")
    static let network = OSLog(subsystem: subsystem, category: "network")
    static let general = OSLog(subsystem: subsystem, category: "general")
    
    // MARK: - Logging Methods
    
    static func info(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .info, message)
    }
    
    static func debug(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .debug, message)
    }
    
    static func error(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .error, message)
    }
    
    static func fault(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .fault, message)
    }
}

