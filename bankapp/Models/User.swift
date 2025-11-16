//
//  User.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import Foundation

struct User: Identifiable, Codable {
    let id: String
    let email: String
    let displayName: String?
    let createdAt: Date
    
    init(id: String, email: String, displayName: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.createdAt = createdAt
    }
    
    // Nombre para mostrar en UI
    var formattedDisplayName: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return email.split(separator: "@").first.map(String.init)?.capitalized ?? "Usuario"
    }
}
