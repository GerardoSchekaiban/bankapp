//
//  ForgotPasswordView.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import SwiftUI

struct ForgotPasswordView: View {
    
    @StateObject private var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.orange.opacity(0.6), Color.red.opacity(0.6)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Icon and title
                    VStack(spacing: 8) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.white)
                        
                        Text("Recuperar Contraseña")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Ingresa tu email y te enviaremos instrucciones para restablecer tu contraseña")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
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
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 4)
                        }
                        
                        // Send button
                        Button(action: {
                            Task {
                                await viewModel.resetPassword()
                            }
                        }) {
                            HStack {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .tint(.orange)
                                } else {
                                    Text("Enviar Email")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(viewModel.isValidEmail ? Color.white : Color.white.opacity(0.5))
                            .foregroundColor(viewModel.isValidEmail ? .orange : .gray)
                            .cornerRadius(12)
                        }
                        .disabled(!viewModel.isValidEmail || viewModel.isLoading)
                        .padding(.top, 8)
                        
                        // Back to login
                        Button(action: {
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("Volver al inicio de sesión")
                            }
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        }
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
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
            .alert("Email Enviado", isPresented: $viewModel.showSuccess) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text(viewModel.successMessage ?? "")
            }
        }
    }
}

#Preview {
    ForgotPasswordView()
}
