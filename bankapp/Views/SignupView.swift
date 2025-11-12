//
//  SignupView.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import SwiftUI

struct SignUpView: View {
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Logo o título
                        VStack(spacing: 8) {
                            Image(systemName: "person.badge.plus.fill")
                                .font(.system(size: 70))
                                .foregroundColor(.white)
                            
                            Text("Crear Cuenta")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Regístrate para comenzar")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 60)
                        .padding(.bottom, 40)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Email field
                            CustomTextField(
                                icon: "envelope.fill",
                                placeholder: "Email",
                                text: $viewModel.email
                            )
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                            
                            if !viewModel.email.isEmpty && !viewModel.isValidEmail {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text("Email inválido")
                                    Spacer()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                            }
                            
                            // Password field
                            CustomSecureField(
                                icon: "lock.fill",
                                placeholder: "Contraseña (mínimo 6 caracteres)",
                                text: $viewModel.password
                            )
                            
                            if !viewModel.password.isEmpty && !viewModel.isValidPassword {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text("La contraseña debe tener al menos 6 caracteres")
                                    Spacer()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                            }
                            
                            // Confirm password field
                            CustomSecureField(
                                icon: "lock.fill",
                                placeholder: "Confirmar Contraseña",
                                text: $viewModel.confirmPassword
                            )
                            
                            if !viewModel.confirmPassword.isEmpty && !viewModel.passwordsMatch {
                                HStack {
                                    Image(systemName: "exclamationmark.circle.fill")
                                    Text("Las contraseñas no coinciden")
                                    Spacer()
                                }
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 4)
                            }
                            
                            // Sign up button
                            Button(action: {
                                Task {
                                    await viewModel.signUp()
                                }
                            }) {
                                HStack {
                                    if viewModel.isLoading {
                                        ProgressView()
                                            .tint(.purple)
                                    } else {
                                        Text("Registrarse")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(viewModel.canSignUp ? Color.white : Color.white.opacity(0.5))
                                .foregroundColor(viewModel.canSignUp ? .purple : .gray)
                                .cornerRadius(12)
                            }
                            .disabled(!viewModel.canSignUp || viewModel.isLoading)
                            .padding(.top, 8)
                            
                            // Already have account
                            HStack {
                                Text("¿Ya tienes cuenta?")
                                    .foregroundColor(.white.opacity(0.8))
                                
                                Button(action: {
                                    dismiss()
                                }) {
                                    Text("Inicia Sesión")
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                }
                            }
                            .font(.subheadline)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 30)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .alert("Éxito", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
            .onChange(of: viewModel.isAuthenticated) { isAuth in
                if isAuth {
                    dismiss()
                }
            }
        }
    }
}

#Preview {
    SignUpView()
}
