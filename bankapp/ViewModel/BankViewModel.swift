//
//  BankViewModel.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 16/11/25.
//

import Foundation
import Combine

@MainActor
class BankViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var cards: [Card] = []
    @Published var selectedCard: Card?
    @Published var recentTransactions: [Transaction] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    @Published var successMessage: String?
    @Published var showSuccess: Bool = false
    
    // Para búsqueda de usuarios
    @Published var searchedUser: User?
    @Published var isSearchingUser: Bool = false
    
    // MARK: - Private Properties
    private let cardRepository: CardRepositoryProtocol
    private let userRepository: UserRepositoryProtocol
    private var userId: String?
    
    // MARK: - Computed Properties
    var totalBalance: Double {
        cards.reduce(0) { $0 + $1.balance }
    }
    
    var formattedTotalBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: totalBalance)) ?? "$0.00"
    }
    
    var primaryCard: Card? {
        cards.first
    }
    
    // MARK: - Initialization
    init(
        cardRepository: CardRepositoryProtocol = CardRepository(),
        userRepository: UserRepositoryProtocol = UserRepository()
    ) {
        self.cardRepository = cardRepository
        self.userRepository = userRepository
    }
    
    // MARK: - Setup
    
    func setUserId(_ userId: String) {
        self.userId = userId
    }
    
    func setupUser(user: User) async {
        self.userId = user.id
        
        // Crear perfil en Firestore si no existe
        do {
            let existingUser = try await userRepository.getUserProfile(userId: user.id)
            if existingUser == nil {
                try await userRepository.createUserProfile(user)
                print("✅ Perfil de usuario creado en Firestore")
            }
        } catch {
            print("⚠️ Error al verificar/crear perfil: \(error)")
        }
        
        await loadCards()
        
        // Si no tiene tarjetas, crear una por defecto
        if cards.isEmpty {
            await createDefaultCard(for: user)
        }
    }
    
    // MARK: - Cards
    
    func loadCards() async {
        guard let userId = userId else { return }
        
        isLoading = true
        
        do {
            cards = try await cardRepository.getCards(userId: userId)
            
            // Cargar transacciones recientes de todas las tarjetas
            await loadRecentTransactions()
            
            print("✅ Tarjetas cargadas: \(cards.count)")
        } catch {
            showErrorMessage("Error al cargar tarjetas: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func createDefaultCard(for user: User) async {
        guard let userId = userId else { return }
        
        let cardNumber = generateCardNumber()
        
        let card = Card(
            userId: userId,
            cardNumber: cardNumber,
            cardHolderName: user.formattedDisplayName,
            cardType: .debit,
            balance: 12500.75, // Balance inicial
            color: "blue"
        )
        
        do {
            try await cardRepository.createCard(card)
            await loadCards()
            print("✅ Tarjeta por defecto creada")
        } catch {
            showErrorMessage("Error al crear tarjeta: \(error.localizedDescription)")
        }
    }
    
    func createCard(
        cardHolderName: String,
        cardType: Card.CardType,
        initialBalance: Double = 0.0,
        color: String = "blue"
    ) async {
        guard let userId = userId else { return }
        
        isLoading = true
        
        let cardNumber = generateCardNumber()
        
        let card = Card(
            userId: userId,
            cardNumber: cardNumber,
            cardHolderName: cardHolderName,
            cardType: cardType,
            balance: initialBalance,
            color: color
        )
        
        do {
            try await cardRepository.createCard(card)
            await loadCards()
            showSuccessMessage("Tarjeta creada exitosamente")
        } catch {
            showErrorMessage("Error al crear tarjeta: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Transactions
    
    func loadRecentTransactions() async {
        guard let userId = userId else { return }
        
        var allTransactions: [Transaction] = []
        
        for card in cards {
            do {
                let transactions = try await cardRepository.getTransactions(
                    cardId: card.id,
                    userId: userId,
                    limit: 20
                )
                allTransactions.append(contentsOf: transactions)
            } catch {
                print("⚠️ Error al cargar transacciones de tarjeta \(card.id): \(error)")
            }
        }
        
        // Ordenar por fecha
        recentTransactions = allTransactions.sorted { $0.date > $1.date }
    }
    
    func performDeposit(amount: Double, cardId: String) async {
        guard let userId = userId else { return }
        
        isLoading = true
        
        let transaction = Transaction(
            cardId: cardId,
            type: .deposit,
            amount: amount,
            description: "Depósito",
            icon: "banknote.fill"
        )
        
        do {
            try await cardRepository.addTransaction(transaction, userId: userId)
            await loadCards()
            showSuccessMessage("Depósito realizado por \(formatCurrency(amount))")
        } catch {
            showErrorMessage("Error al realizar depósito: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    func performWithdraw(amount: Double, cardId: String) async {
        guard let userId = userId else { return }
        guard let card = cards.first(where: { $0.id == cardId }) else { return }
        
        if card.balance < amount {
            showErrorMessage("Saldo insuficiente para retirar \(formatCurrency(amount))")
            return
        }
        
        isLoading = true
        
        let transaction = Transaction(
            cardId: cardId,
            type: .withdraw,
            amount: amount,
            description: "Retiro",
            icon: "minus.circle.fill"
        )
        
        do {
            try await cardRepository.addTransaction(transaction, userId: userId)
            await loadCards()
            showSuccessMessage("Retiro realizado por \(formatCurrency(amount))")
        } catch {
            showErrorMessage("Error al realizar retiro: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Transfer Between Users
    
    func searchUser(byEmail email: String) async {
        guard !email.isEmpty else {
            showErrorMessage("Ingresa un email válido")
            return
        }
        
        isSearchingUser = true
        searchedUser = nil
        
        do {
            if let user = try await userRepository.searchUserByEmail(email: email) {
                // No permitir transferir a sí mismo
                if user.id == userId {
                    showErrorMessage("No puedes transferir a tu propia cuenta")
                    isSearchingUser = false
                    return
                }
                searchedUser = user
                print("✅ Usuario encontrado: \(user.email)")
            } else {
                showErrorMessage("No se encontró ningún usuario con ese email")
            }
        } catch {
            showErrorMessage("Error al buscar usuario: \(error.localizedDescription)")
        }
        
        isSearchingUser = false
    }
    
    func transferToUser(
        fromCardId: String,
        toUser: User,
        amount: Double,
        description: String
    ) async {
        guard let userId = userId else { return }
        guard let fromCard = cards.first(where: { $0.id == fromCardId }) else {
            showErrorMessage("Tarjeta de origen no encontrada")
            return
        }
        
        // Validar saldo
        if fromCard.balance < amount {
            showErrorMessage("Saldo insuficiente para transferir \(formatCurrency(amount))")
            return
        }
        
        isLoading = true
        
        do {
            // Obtener tarjeta principal del destinatario
            let toUserCards = try await cardRepository.getCards(userId: toUser.id)
            guard let toCard = toUserCards.first else {
                showErrorMessage("El usuario destinatario no tiene tarjetas")
                isLoading = false
                return
            }
            
            // Realizar transferencia atómica
            try await cardRepository.transferBetweenUsers(
                fromCardId: fromCard.id,
                fromUserId: userId,
                toCardId: toCard.id,
                toUserId: toUser.id,
                amount: amount,
                description: description
            )
            
            await loadCards()
            showSuccessMessage("Transferencia exitosa a \(toUser.formattedDisplayName)")
            searchedUser = nil
            
        } catch {
            showErrorMessage("Error en la transferencia: \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    // MARK: - Helpers
    
    private func generateCardNumber() -> String {
        let digits = (0..<16).map { _ in String(Int.random(in: 0...9)) }.joined()
        return digits
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func showErrorMessage(_ message: String) {
        errorMessage = message
        showError = true
    }
    
    private func showSuccessMessage(_ message: String) {
        successMessage = message
        showSuccess = true
    }
}
