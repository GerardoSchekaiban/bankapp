//
//  HomeView.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 28/10/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var bankViewModel = BankViewModel()
    
    // Estados para sheets
    @State private var showTransferSheet = false
    @State private var showDepositSheet = false
    @State private var showWithdrawSheet = false
    @State private var showCardSelector = false
    
    // Valores de inputs
    @State private var transferAmountText = ""
    @State private var depositAmountText = ""
    @State private var withdrawAmountText = ""
    @State private var recipientEmail = ""
    @State private var transferDescription = ""
    
    // Tarjeta seleccionada para operaciones
    @State private var selectedCardForOperation: Card?
    
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
                        headerSection
                        
                        // Tarjeta de Saldo
                        balanceCard
                        
                        // Últimos movimientos
                        transactionsSection
                        
                        // Perfil
                        profileSection
                    }
                    .padding(.vertical, 24)
                }
                
                if bankViewModel.isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
            .navigationTitle("Inicio")
            .task {
                if let user = authViewModel.currentUser {
                    await bankViewModel.setupUser(user: user)
                }
            }
            .alert("Éxito", isPresented: $bankViewModel.showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(bankViewModel.successMessage ?? "")
            }
            .alert("Error", isPresented: $bankViewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(bankViewModel.errorMessage ?? "")
            }
            .sheet(isPresented: $showTransferSheet) {
                transferSheet
            }
            .sheet(isPresented: $showDepositSheet) {
                depositSheet
            }
            .sheet(isPresented: $showWithdrawSheet) {
                withdrawSheet
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
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
    }
    
    // MARK: - Balance Card
    
    private var balanceCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Saldo total")
                    .font(.headline)
                Spacer()
                if bankViewModel.cards.count > 1 {
                    Text("\(bankViewModel.cards.count) tarjetas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(bankViewModel.formattedTotalBalance)
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
    }
    
    // MARK: - Transactions Section
    
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Últimos movimientos")
                .font(.headline)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
            
            if bankViewModel.recentTransactions.isEmpty {
                emptyTransactionsView
            } else {
                ForEach(bankViewModel.recentTransactions.prefix(10)) { tx in
                    transactionRow(tx)
                    Divider()
                        .padding(.leading, 64)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 4)
        .padding(.horizontal, 24)
    }
    
    private var emptyTransactionsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("No hay movimientos recientes")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private func transactionRow(_ tx: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: tx.icon)
                .foregroundColor(tx.amountColor == "green" ? .green : .red)
                .frame(width: 28)
            
            VStack(alignment: .leading) {
                Text(tx.description)
                    .fontWeight(.medium)
                
                if let relatedEmail = tx.relatedUserEmail {
                    Text(tx.type == .received ? "De: \(relatedEmail)" : "A: \(relatedEmail)")
                        .foregroundColor(.secondary)
                        .font(.caption)
                } else {
                    Text(dateFormatter.string(from: tx.date))
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Text(tx.formattedAmount(showSign: true))
                .fontWeight(.semibold)
                .foregroundColor(tx.amountColor == "green" ? .green : .red)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue)
                VStack(alignment: .leading) {
                    Text(authViewModel.currentUser?.email ?? "Invitado")
                        .font(.headline)
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
    
    // MARK: - Transfer Sheet
    
    private var transferSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nueva Transferencia")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                // Buscar usuario
                VStack(alignment: .leading, spacing: 8) {
                    Text("Email del destinatario")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("correo@ejemplo.com", text: $recipientEmail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
                        
                        Button(action: {
                            Task {
                                await bankViewModel.searchUser(byEmail: recipientEmail)
                            }
                        }) {
                            if bankViewModel.isSearchingUser {
                                ProgressView()
                            } else {
                                Text("Buscar")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(recipientEmail.isEmpty || bankViewModel.isSearchingUser)
                    }
                }
                
                // Usuario encontrado
                if let searchedUser = bankViewModel.searchedUser {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        VStack(alignment: .leading) {
                            Text(searchedUser.formattedDisplayName)
                                .fontWeight(.semibold)
                            Text(searchedUser.email)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    // Cantidad
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cantidad a transferir")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("0.00", text: $transferAmountText)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Descripción
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Descripción (opcional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        TextField("Concepto", text: $transferDescription)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    // Botones
                    HStack {
                        Button("Cancelar") {
                            resetTransferForm()
                            showTransferSheet = false
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Confirmar") {
                            Task {
                                await performTransfer()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(transferAmountText.isEmpty || bankViewModel.isLoading)
                    }
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Transferir")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        resetTransferForm()
                        showTransferSheet = false
                    }
                }
            }
        }
    }
    
    // MARK: - Deposit Sheet
    
    private var depositSheet: some View {
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
                    
                    Button(bankViewModel.isLoading ? "Procesando..." : "Confirmar") {
                        Task {
                            await performDeposit()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(bankViewModel.isLoading || depositAmountText.isEmpty)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Depositar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Withdraw Sheet
    
    private var withdrawSheet: some View {
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
                    
                    Button(bankViewModel.isLoading ? "Procesando..." : "Confirmar") {
                        Task {
                            await performWithdraw()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(bankViewModel.isLoading || withdrawAmountText.isEmpty)
                }
                .padding(.top, 8)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Retirar")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Actions
    
    private func performTransfer() async {
        guard let searchedUser = bankViewModel.searchedUser,
              let primaryCard = bankViewModel.primaryCard else { return }
        
        let raw = transferAmountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(raw), amount > 0 else {
            bankViewModel.errorMessage = "Ingresa una cantidad válida mayor a $0"
            bankViewModel.showError = true
            return
        }
        
        let description = transferDescription.isEmpty ? "Transferencia a \(searchedUser.formattedDisplayName)" : transferDescription
        
        await bankViewModel.transferToUser(
            fromCardId: primaryCard.id,
            toUser: searchedUser,
            amount: amount,
            description: description
        )
        
        resetTransferForm()
        showTransferSheet = false
    }
    
    private func performDeposit() async {
        guard let primaryCard = bankViewModel.primaryCard else { return }
        
        let raw = depositAmountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(raw), amount > 0 else {
            bankViewModel.errorMessage = "Ingresa una cantidad válida mayor a $0"
            bankViewModel.showError = true
            return
        }
        
        await bankViewModel.performDeposit(amount: amount, cardId: primaryCard.id)
        
        depositAmountText = ""
        showDepositSheet = false
    }
    
    private func performWithdraw() async {
        guard let primaryCard = bankViewModel.primaryCard else { return }
        
        let raw = withdrawAmountText.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
        guard let amount = Double(raw), amount > 0 else {
            bankViewModel.errorMessage = "Ingresa una cantidad válida mayor a $0"
            bankViewModel.showError = true
            return
        }
        
        await bankViewModel.performWithdraw(amount: amount, cardId: primaryCard.id)
        
        withdrawAmountText = ""
        showWithdrawSheet = false
    }
    
    private func resetTransferForm() {
        recipientEmail = ""
        transferAmountText = ""
        transferDescription = ""
        bankViewModel.searchedUser = nil
    }
    
    // MARK: - Helpers
    
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
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        df.locale = Locale(identifier: "es_MX")
        return df
    }
}

#Preview {
    let vm = AuthViewModel()
    vm.currentUser = User(id: "123", email: "usuario@bankapp.com")
    vm.isAuthenticated = true
    return HomeView().environmentObject(vm)
}
