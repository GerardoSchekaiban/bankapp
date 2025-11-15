//
//  LoginView.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject private var viewModel: AuthViewModel
    @State private var showSignUp = false
    @State private var showForgotPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fondo
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Logo
                    VStack(spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Bienvenido")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Inicia sesión para continuar")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 40)
                    
                    // Inputs
                    VStack(spacing: 16) {
                        // Email field
                        CustomTextField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $viewModel.email
                        )
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                        
                        // Password field
                        CustomSecureField(
                            icon: "lock.fill",
                            placeholder: "Contraseña",
                            text: $viewModel.password
                        )
                        
                        // Olvidaste tu contraseña
                        HStack {
                            Spacer()
                            Button(action: {
                                showForgotPassword = true
                            }) {
                                Text("¿Olvidaste tu contraseña?")
                                    .font(.footnote)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Botón Iniciar Sesión
                        Button(action: {
                            Task {
                                await viewModel.signIn()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Iniciar Sesión")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.canSignIn ? Color.white : Color.white.opacity(0.5))
                            .foregroundColor(viewModel.canSignIn ? .blue : .gray)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.canSignIn || viewModel.isLoading)
                        .padding(.top, 8)
                        
                        // Link a Registrarse
                        HStack {
                            Text("¿No tienes cuenta?")
                                .foregroundColor(.white.opacity(0.8))
                            
                            Button(action: {
                                showSignUp = true
                            }) {
                                Text("Regístrate")
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                            }
                        }
                        .font(.subheadline)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Éxito", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .sheet(isPresented: $showSignUp) {
                SignUpView()
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
            }
            // Presentación del Home ahora la maneja bankappApp con authViewModel compartido
        }
    }
}

// MARK: - Custom TextField
struct CustomTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .placeholder(when: text.isEmpty) {
                    Text(placeholder)
                        .foregroundColor(.white.opacity(0.6))
                }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Custom SecureField
struct CustomSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isSecure: Bool = true
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
            }
            
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: isSecure ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(Color.white.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - View Extension for Placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
