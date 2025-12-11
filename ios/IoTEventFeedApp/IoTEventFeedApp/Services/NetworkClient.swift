//
//  NetworkClient.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftUI

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized(Data)
    case serverError(Int)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized(_):
            return "Unauthorized"
        case .serverError(let code):
            return "Server error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

final class NetworkClient {
    private static let localhostURL = "http://localhost:8080"
    
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String = localhostURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func fullURL(for path: String) -> URL? {
        if path.hasPrefix("http://") || path.hasPrefix("https://") {
            return URL(string: path)
        }
        return URL(string: "\(baseURL)\(path)")
    }
    
    func request<T: Decodable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        appSession: AppSession? = nil
    ) async throws -> T {
        var components = URLComponents(string: "\(baseURL)\(endpoint)")!
        
        if let queryItems = queryItems {
            components.queryItems = queryItems
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        
        // Automatically attach Authorization header if token is available
        let token: String? = await appSession?.token
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Set Content-Type for POST/PUT requests
        if let body = body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw NetworkError.decodingError(error)
                }
            case 401:
                // Handle unauthorized for all requests.
                // Auto-logout if user was logged in
                if let appSession = appSession {
                    await appSession.logout()
                }
                throw NetworkError.unauthorized(data)
            default:
                throw NetworkError.serverError(httpResponse.statusCode)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}

// Environment key for NetworkClient
private struct NetworkClientKey: EnvironmentKey {
    static let defaultValue = NetworkClient()
}

extension EnvironmentValues {
    var networkClient: NetworkClient {
        get { self[NetworkClientKey.self] }
        set { self[NetworkClientKey.self] = newValue }
    }
}
