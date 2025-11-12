//
//  AuthRepository.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import Foundation
import Firebase
import FirebaseAuth

protocol AuthRepositoryProtocol {
    func signUp(email: String, password: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    func signOut() throws
    func getCurrentUser() -> User?
    func resetPassword(email: String) async throws
}

class AuthRepository: AuthRepositoryProtocol {
    
    private let auth = Auth.auth()
    
    // MARK: - Sign Up
    func signUp(email: String, password: String) async throws -> User {
        let result = try await auth.createUser(withEmail: email, password: password)
        return User(id: result.user.uid, email: email)
    }
    
    // MARK: - Sign In
    func signIn(email: String, password: String) async throws -> User {
        let result = try await auth.signIn(withEmail: email, password: password)
        return User(id: result.user.uid, email: result.user.email ?? email)
    }
    
    // MARK: - Sign Out
    func signOut() throws {
        try auth.signOut()
    }
    
    // MARK: - Get Current User
    func getCurrentUser() -> User? {
        guard let firebaseUser = auth.currentUser else { return nil }
        return User(id: firebaseUser.uid, email: firebaseUser.email ?? "")
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
}
