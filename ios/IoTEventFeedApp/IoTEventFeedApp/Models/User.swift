//
//  User.swift
//  IoTEventFeedApp
//
//  Created by Nikola Zagorchev on 10.12.25.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: String
    var username: String
    var email: String
    var name: String
    var role: String
    
    init(id: String, username: String, email: String, name: String, role: String) {
        self.id = id
        self.username = username
        self.email = email
        self.name = name
        self.role = role
    }
    
    convenience init(from apiUser: APIUser) {
        self.init(
            id: apiUser.id,
            username: apiUser.username,
            email: apiUser.email,
            name: apiUser.name,
            role: apiUser.role
        )
    }
}
