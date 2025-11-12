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
    let createdAt: Date
    
    init(id: String, email: String, createdAt: Date = Date()) {
        self.id = id
        self.email = email
        self.createdAt = createdAt
    }
}
