//
//  AuthViewModel.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class AuthViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var currentUser: User?
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var successMessage: String?
    @Published var showSuccess: Bool = false
    
    // MARK: - Private Properties
    private let repository: AuthRepositoryProtocol
    
    // MARK: - Computed Properties
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isValidPassword: Bool {
        return password.count >= 6
    }
    
    var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    var canSignIn: Bool {
        return isValidEmail && isValidPassword
    }
    
    var canSignUp: Bool {
        return isValidEmail && isValidPassword && passwordsMatch
    }
    
    // Nombre para UI: usa displayName de Firebase si existe; si no, toma la parte antes del '@' del email; si no, 'Usuario'
    var displayName: String {
        if let name = Auth.auth().currentUser?.displayName, !name.isEmpty {
            return name
        }
        if let email = currentUser?.email {
            let base = email.split(separator: "@").first.map(String.init) ?? "Usuario"
            return base.capitalized
        }
        return "Usuario"
    }
    
    // MARK: - Initialization
    init(repository: AuthRepositoryProtocol = AuthRepository()) {
        self.repository = repository
        checkAuthentication()
    }
    
    // MARK: - Public Methods
    
    func signUp() async {
        guard canSignUp else {
            showErrorMessage("Por favor completa todos los campos correctamente")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await repository.signUp(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            clearFields()
            showSuccessMessage("¡Cuenta creada exitosamente!")
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signIn() async {
        guard canSignIn else {
            showErrorMessage("Por favor ingresa email y contraseña válidos")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await repository.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
            clearFields()
            showSuccessMessage("¡Bienvenido de nuevo!")
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try repository.signOut()
            currentUser = nil
            isAuthenticated = false
            clearFields()
        } catch {
            showErrorMessage("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
    
    func resetPassword() async {
        guard isValidEmail else {
            showErrorMessage("Por favor ingresa un email válido")
            return
        }
        
        isLoading = true
        
        do {
            try await repository.resetPassword(email: email)
            showSuccessMessage("Email de recuperación enviado. Revisa tu bandeja de entrada.")
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    func checkAuthentication() {
        currentUser = repository.getCurrentUser()
        isAuthenticated = currentUser != nil
    }
    
    // MARK: - Private Methods
    
    private func clearFields() {
        email = ""
        password = ""
        confirmPassword = ""
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
    
    private func handleAuthError(_ error: Error) {
        let nsError = error as NSError
        
        switch nsError.code {
        case 17007: // Email already in use
            showErrorMessage("Este email ya está registrado")
        case 17008, 17011: // Invalid email or wrong password
            showErrorMessage("Email o contraseña incorrectos")
        case 17026: // Weak password
            showErrorMessage("La contraseña debe tener al menos 6 caracteres")
        case 17020: // Network error
            showErrorMessage("Error de conexión. Verifica tu internet")
        case 17009: // Wrong password
            showErrorMessage("Contraseña incorrecta")
        case 17011: // User not found
            showErrorMessage("No existe una cuenta con este email")
        default:
            showErrorMessage("Error: \(error.localizedDescription)")
        }
    }
}
