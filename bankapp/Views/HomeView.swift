//
//  HomeView.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var balance: Double = 12500.75
    
    struct Transaction: Identifiable, Codable {
        let id = UUID()
        let title: String
        let amount: Double
        let date: Date
        let icon: String
    }
    
    @State private var recentTransactions: [Transaction] = [
        Transaction(title: "Pago Netflix", amount: -199.0, date: Date(), icon: "play.tv.fill"),
        Transaction(title: "Depósito Nómina", amount: 8500.0, date: Date().addingTimeInterval(-86400), icon: "banknote.fill"),
        Transaction(title: "Transferencia OXXO", amount: -150.0, date: Date().addingTimeInterval(-172800), icon: "cart.fill")
    ]
    
    // Estado para transferencia
    @State private var showTransferSheet = false
    @State private var transferAmountText = ""
    @State private var isProcessingTransfer = false
    // Estado para depósito
    @State private var showDepositSheet = false
    @State private var depositAmountText = ""
    @State private var isProcessingDeposit = false
    // Estado para retiro
    @State private var showWithdrawSheet = false
    @State private var withdrawAmountText = ""
    @State private var isProcessingWithdraw = false
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.15), Color.purple.opacity(0.15)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Encabezado
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Hola,")
                                    .font(.title3)
                                    .foregroundColor(.secondary)
                                Text(authViewModel.displayName)
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            Spacer()
                            Button(action: {
                                authViewModel.signOut()
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.forward")
                                    Text("Cerrar sesión")
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.horizontal, 24)
                        
                        // Tarjeta de Saldo
                        VStack(spacing: 12) {
                            HStack {
                                Text("Saldo disponible")
                                    .font(.headline)
                                Spacer()
                            }
                            HStack(alignment: .firstTextBaseline) {
                                Text("$\(String(format: "%.2f", balance))")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                Spacer()
                            }
                            HStack(spacing: 12) {
                                actionButton(icon: "arrow.up.right.circle.fill", title: "Transferir") {
                                    showTransferSheet = true
                                }
                                actionButton(icon: "plus.circle.fill", title: "Depositar") {
                                    showDepositSheet = true
                                }
                                actionButton(icon: "minus.circle.fill", title: "Retirar") {
                                    showWithdrawSheet = true
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        
                        // Últimos movimientos
                        VStack(alignment: .leading, spacing: 0) {
                            Text("Últimos movimientos")
                                .font(.headline)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                            ForEach(recentTransactions) { tx in
                                HStack(spacing: 12) {
                                    Image(systemName: tx.icon)
                                        .foregroundColor(tx.amount >= 0 ? .green : .red)
                                        .frame(width: 28)
                                    VStack(alignment: .leading) {
                                        Text(tx.title)
                                            .fontWeight(.medium)
                                        Text(dateFormatter.string(from: tx.date))
                                            .foregroundColor(.secondary)
                                            .font(.caption)
                                    }
                                    Spacer()
                                    Text(formattedAmount(tx.amount))
                                        .fontWeight(.semibold)
                                        .foregroundColor(tx.amount >= 0 ? .green : .red)
                                }
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                Divider()
                                    .padding(.leading, 64)
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.ultraThinMaterial)
                        )
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 4)
                        .padding(.horizontal, 24)
                        
                        // Perfil
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading) {
                                    Text(authViewModel.currentUser?.email ?? "Invitado")
                                        .font(.headline)
                                    // Removed ID display
                                }
                                Spacer()
                            }
                            .padding()
                        }
                        .background(.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 24)
                    .onAppear {
                        loadPersistedStateForCurrentUser()
                    }
                }
            }
            .navigationTitle("Inicio")
            .alert("Éxito", isPresented: $authViewModel.showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: $authViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authViewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showTransferSheet) {
                NavigationView {
                    VStack(spacing: 16) {
                        Text("Nueva Transferencia")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        TextField("Cantidad", text: $transferAmountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Button("Cancelar") {
                                showTransferSheet = false
                                transferAmountText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Button(isProcessingTransfer ? "Procesando..." : "Confirmar") {
                                performTransfer()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isProcessingTransfer)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Transferir")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showDepositSheet) {
                NavigationView {
                    VStack(spacing: 16) {
                        Text("Nuevo Depósito")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        TextField("Cantidad", text: $depositAmountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Button("Cancelar") {
                                showDepositSheet = false
                                depositAmountText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Button(isProcessingDeposit ? "Procesando..." : "Confirmar") {
                                performDeposit()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isProcessingDeposit)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Depositar")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showWithdrawSheet) {
                NavigationView {
                    VStack(spacing: 16) {
                        Text("Nuevo Retiro")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        TextField("Cantidad", text: $withdrawAmountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        HStack {
                            Button("Cancelar") {
                                showWithdrawSheet = false
                                withdrawAmountText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Button(isProcessingWithdraw ? "Procesando..." : "Confirmar") {
                                performWithdraw()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(isProcessingWithdraw)
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                    .navigationTitle("Retirar")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }
    
    private func formattedAmount(_ amount: Double) -> String {
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)$\(String(format: "%.2f", amount))"
    }
    
    // Persistencia local por usuario (UserDefaults)
    private func persistStateForCurrentUser() {
        guard let uid = authViewModel.currentUser?.id else { return }
        let balanceKey = "balance_\(uid)"
        let txKey = "transactions_\(uid)"
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let txData = try? encoder.encode(recentTransactions) {
            UserDefaults.standard.set(txData, forKey: txKey)
        }
        UserDefaults.standard.set(balance, forKey: balanceKey)
    }
    
    private func loadPersistedStateForCurrentUser() {
        guard let uid = authViewModel.currentUser?.id else { return }
        let balanceKey = "balance_\(uid)"
        let txKey = "transactions_\(uid)"
        let defaults = UserDefaults.standard
        if defaults.object(forKey: balanceKey) != nil {
            let savedBalance = defaults.double(forKey: balanceKey)
            balance = savedBalance
        }
        if let data = defaults.data(forKey: txKey) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            if let savedTxs = try? decoder.decode([Transaction].self, from: data) {
                recentTransactions = savedTxs
            }
        }
    }
    
    private func performTransfer() {
        guard !isProcessingTransfer else { return }
        isProcessingTransfer = true
        let raw = transferAmountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(raw), amount > 0 else {
            authViewModel.errorMessage = "Ingresa una cantidad válida mayor a $0"
            authViewModel.showError = true
            isProcessingTransfer = false
            return
        }
        guard amount <= balance else {
            authViewModel.errorMessage = "Saldo insuficiente para transferir $\(String(format: "%.2f", amount))"
            authViewModel.showError = true
            isProcessingTransfer = false
            return
        }
        
        withAnimation {
            balance -= amount
            let tx = Transaction(title: "Transferencia", amount: -amount, date: Date(), icon: "arrow.up.right.circle.fill")
            recentTransactions.insert(tx, at: 0)
        }
        persistStateForCurrentUser()
        
        authViewModel.successMessage = "Transferencia realizada por $\(String(format: "%.2f", amount))"
        authViewModel.showSuccess = true
        transferAmountText = ""
        showTransferSheet = false
        isProcessingTransfer = false
    }
    
    private func performDeposit() {
        guard !isProcessingDeposit else { return }
        isProcessingDeposit = true
        let raw = depositAmountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(raw), amount > 0 else {
            authViewModel.errorMessage = "Ingresa una cantidad válida mayor a $0"
            authViewModel.showError = true
            isProcessingDeposit = false
            return
        }
        
        withAnimation {
            balance += amount
            let tx = Transaction(title: "Depósito", amount: amount, date: Date(), icon: "banknote.fill")
            recentTransactions.insert(tx, at: 0)
        }
        persistStateForCurrentUser()
        
        authViewModel.successMessage = "Depósito realizado por $\(String(format: "%.2f", amount))"
        authViewModel.showSuccess = true
        depositAmountText = ""
        showDepositSheet = false
        isProcessingDeposit = false
    }
    
    private func performWithdraw() {
        guard !isProcessingWithdraw else { return }
        isProcessingWithdraw = true
        let raw = withdrawAmountText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(raw), amount > 0 else {
            authViewModel.errorMessage = "Ingresa una cantidad válida mayor a $0"
            authViewModel.showError = true
            isProcessingWithdraw = false
            return
        }
        guard amount <= balance else {
            authViewModel.errorMessage = "Saldo insuficiente para retirar $\(String(format: "%.2f", amount))"
            authViewModel.showError = true
            isProcessingWithdraw = false
            return
        }
        
        withAnimation {
            balance -= amount
            let tx = Transaction(title: "Retiro", amount: -amount, date: Date(), icon: "minus.circle.fill")
            recentTransactions.insert(tx, at: 0)
        }
        persistStateForCurrentUser()
        
        authViewModel.successMessage = "Retiro realizado por $\(String(format: "%.2f", amount))"
        authViewModel.showSuccess = true
        withdrawAmountText = ""
        showWithdrawSheet = false
        isProcessingWithdraw = false
    }
    
    @ViewBuilder
    private func actionButton(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .background(
                Capsule().fill(Color.white.opacity(0.9))
            )
            .overlay(
                Capsule().stroke(Color.blue.opacity(0.25), lineWidth: 1)
            )
        }
        .foregroundColor(.blue)
        .shadow(color: Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
}
// Cierra la estructura HomeView antes del bloque de #Preview
}

#Preview {
    let vm = AuthViewModel()
    vm.currentUser = User(id: "123", email: "usuario@bankapp.com")
    vm.isAuthenticated = true
    return HomeView().environmentObject(vm)
}
