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
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
