//
//  APIService.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation

// MARK: - API Localized Error

enum APIError: LocalizedError {
    case unauthorized(String)
    
    var errorDescription: String? {
        switch self {
        case .unauthorized(let message):
            return message
        }
    }
}

// MARK: - API Service

final class APIService {
    private let networkClient: NetworkClient
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    // MARK: - Authentication
    
    func login(username: String, password: String) async throws -> LoginResponse {
        do {
            let loginRequest = LoginRequest(username: username, password: password)
            return try await networkClient.request(
                endpoint: "/api/login",
                method: "POST",
                body: loginRequest,
                appSession: nil
            )
        } catch let NetworkError.unauthorized(data) {
            let errorMessage: String
            if let errorResponse = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                errorMessage = errorResponse.message ?? errorResponse.error
            } else {
                errorMessage = "Unauthorized"
            }
            
            throw APIError.unauthorized(errorMessage)
        }
    }
    
    // MARK: - Events
    
    func getEvents(
        limit: Int? = nil,
        afterCursor: Cursor? = nil,
        beforeCursor: Cursor? = nil,
        appSession: AppSession
    ) async throws -> EventListResponse {
        var queryItems: [URLQueryItem] = []
        
        if let limit = limit {
            queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
        }
        
        if let cursor = afterCursor {
            queryItems.append(URLQueryItem(name: "after_ts", value: "\(cursor.timestamp)"))
            queryItems.append(URLQueryItem(name: "after_id", value: cursor.eventID))
        }
        
        if let cursor = beforeCursor {
            queryItems.append(URLQueryItem(name: "before_ts", value: "\(cursor.timestamp)"))
            queryItems.append(URLQueryItem(name: "before_id", value: cursor.eventID))
        }
        
        return try await networkClient.request(
            endpoint: "/api/events",
            queryItems: queryItems.isEmpty ? nil : queryItems,
            appSession: appSession
        )
    }
    
    func getEvent(id: String, appSession: AppSession) async throws -> APIEvent {
        return try await networkClient.request(
            endpoint: "/api/events/\(id)",
            appSession: appSession
        )
    }
    
    func getNewEventsCount(afterTimestamp: Int64, appSession: AppSession) async throws -> NewEventsCountResponse {
        let queryItems = [
            URLQueryItem(name: "after_ts", value: "\(afterTimestamp)")
        ]
        
        return try await networkClient.request(
            endpoint: "/api/events/new/count",
            queryItems: queryItems,
            appSession: appSession
        )
    }
    
    // MARK: - User Profile
    
    func getUserProfile(id: String, appSession: AppSession) async throws -> APIUser {
        return try await networkClient.request(
            endpoint: "/api/user/\(id)",
            appSession: appSession
        )
    }
}
