//
//  WelcomeCardView.swift
//  bankapp
//
//  Created by Trae on 15/11/25.
//

import SwiftUI

struct WelcomeCardView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var navigateToHome: Bool = false
    @State private var cardNumber: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Bienvenido")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    NavigationLink(destination: HomeView(), isActive: $navigateToHome) {
                        EmptyView()
                    }
                    .hidden()
                    
                    Button(action: {
                        navigateToHome = true
                    }) {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(authViewModel.displayName)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                Spacer()
                                Image(systemName: "creditcard.fill")
                                    .foregroundColor(.white)
                            }
                            
                            Text(cardNumber)
                                .font(.title3)
                                .monospacedDigit()
                                .foregroundColor(.white.opacity(0.95))
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 8)
                        .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    
                    Text("Toca la tarjeta para continuar")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 40)
            }
            .onAppear {
                if cardNumber.isEmpty {
                    cardNumber = generateCardNumber()
                }
            }
            .navigationTitle("Tu tarjeta")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func generateCardNumber() -> String {
        // Genera 16 dígitos y los agrupa 4-4-4-4
        let digits = (0..<16).map { _ in String(Int.random(in: 0...9)) }.joined()
        return stride(from: 0, to: digits.count, by: 4)
            .map { i -> String in
                let start = digits.index(digits.startIndex, offsetBy: i)
                let end = digits.index(start, offsetBy: 4)
                return String(digits[start..<end])
            }
            .joined(separator: " ")
    }
}

#Preview {
    let vm = AuthViewModel()
    vm.currentUser = User(id: "123", email: "usuario@bankapp.com")
    vm.isAuthenticated = true
    return WelcomeCardView().environmentObject(vm)
}