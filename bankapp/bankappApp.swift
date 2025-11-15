//
//  bankappApp.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import SwiftUI
import Firebase

@main
struct bankappApp: App {
    
    init() {
            // Configurar Firebase
            FirebaseApp.configure()
        }
    
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    WelcomeCardView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                        .environmentObject(authViewModel)
                }
            }
        }
    }
}
