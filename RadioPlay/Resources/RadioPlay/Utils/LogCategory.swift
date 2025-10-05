//
//  LogCategory.swift
//  RadioPlay
//
//  Created by Martin Parmentier on 17/05/2025.
//


// Utils/Logger.swift
import Foundation
import os.log

enum LogCategory: String {
    case network = "Network"
    case audio = "Audio"
    case database = "Database"
    case ui = "UI"
}

class Logger {
    static func log(_ message: String, category: LogCategory, type: OSLogType = .default) {
        #if DEBUG
        let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.radioplay", category: category.rawValue)
        os_log("%{public}@", log: logger, type: type, message)
        #endif
    }
}