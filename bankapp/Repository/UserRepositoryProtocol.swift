//
//  UserRepositoryProtocol.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 16/11/25.
//

import Foundation
import FirebaseFirestore

protocol UserRepositoryProtocol {
    func createUserProfile(_ user: User) async throws
    func getUserProfile(userId: String) async throws -> User?
    func searchUserByEmail(email: String) async throws -> User?
    func getAllUsers() async throws -> [User]
}

class UserRepository: UserRepositoryProtocol {
    
    private let db = Firestore.firestore()
    
    // MARK: - Create User Profile
    func createUserProfile(_ user: User) async throws {
        let userRef = db.collection("users").document(user.id)
        try userRef.setData(from: user)
    }
    
    // MARK: - Get User Profile
    func getUserProfile(userId: String) async throws -> User? {
        let snapshot = try await db.collection("users").document(userId).getDocument()
        return try? snapshot.data(as: User.self)
    }
    
    // MARK: - Search User by Email
    func searchUserByEmail(email: String) async throws -> User? {
        let snapshot = try await db.collection("users")
            .whereField("email", isEqualTo: email.lowercased())
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return try? document.data(as: User.self)
    }
    
    // MARK: - Get All Users (para testing)
    func getAllUsers() async throws -> [User] {
        let snapshot = try await db.collection("users").getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
}
