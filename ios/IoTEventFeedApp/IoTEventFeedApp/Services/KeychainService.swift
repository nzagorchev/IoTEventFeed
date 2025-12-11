//
//  KeychainService.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case unexpectedData
    case unhandledError(status: OSStatus)
    
    var localizedDescription: String {
        switch self {
        case .itemNotFound:
            return "Item not found in keychain"
        case .unexpectedData:
            return "Unexpected data format"
        case .unhandledError(let status):
            return "Keychain error: \(status)"
        }
    }
}

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.ioteventfeed.app"
    
    private init() {}
    
    // MARK: - Token Storage
    
    func saveToken(_ token: String, forKey key: String) throws {
        let data = token.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item if it exists
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func getToken(forKey key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status != errSecItemNotFound else {
            throw KeychainError.itemNotFound
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.unexpectedData
        }
        
        return token
    }
    
    func deleteToken(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Generic String Storage
    
    func save(_ value: String, forKey key: String) throws {
        try saveToken(value, forKey: key)
    }
    
    func get(forKey key: String) throws -> String {
        return try getToken(forKey: key)
    }
    
    func delete(forKey key: String) throws {
        try deleteToken(forKey: key)
    }
}

