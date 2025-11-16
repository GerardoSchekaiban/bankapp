//
//  CardRepository.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 16/11/25.
//

import Foundation
import FirebaseFirestore

protocol CardRepositoryProtocol {
    func createCard(_ card: Card) async throws
    func getCards(userId: String) async throws -> [Card]
    func updateCard(_ card: Card) async throws
    func deleteCard(cardId: String, userId: String) async throws
    func getTransactions(cardId: String, userId: String, limit: Int) async throws -> [Transaction]
    func addTransaction(_ transaction: Transaction, userId: String) async throws
    func transferBetweenUsers(
        fromCardId: String,
        fromUserId: String,
        toCardId: String,
        toUserId: String,
        amount: Double,
        description: String
    ) async throws
}

class CardRepository: CardRepositoryProtocol {
    
    private let db = Firestore.firestore()
    
    // MARK: - Cards
    
    func createCard(_ card: Card) async throws {
        let cardRef = db.collection("users").document(card.userId).collection("cards").document(card.id)
        try cardRef.setData(from: card)
    }
    
    func getCards(userId: String) async throws -> [Card] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("cards")
            .order(by: "createdAt", descending: false)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Card.self)
        }
    }
    
    func updateCard(_ card: Card) async throws {
        let cardRef = db.collection("users").document(card.userId).collection("cards").document(card.id)
        try cardRef.setData(from: card, merge: true)
    }
    
    func deleteCard(cardId: String, userId: String) async throws {
        try await db.collection("users")
            .document(userId)
            .collection("cards")
            .document(cardId)
            .delete()
    }
    
    // MARK: - Transactions
    
    func getTransactions(cardId: String, userId: String, limit: Int = 50) async throws -> [Transaction] {
        let snapshot = try await db.collection("users")
            .document(userId)
            .collection("cards")
            .document(cardId)
            .collection("transactions")
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            try? document.data(as: Transaction.self)
        }
    }
    
    func addTransaction(_ transaction: Transaction, userId: String) async throws {
        let transactionRef = db.collection("users")
            .document(userId)
            .collection("cards")
            .document(transaction.cardId)
            .collection("transactions")
            .document(transaction.id)
        
        try transactionRef.setData(from: transaction)
        
        // Actualizar balance de la tarjeta
        try await updateCardBalance(cardId: transaction.cardId, userId: userId, transaction: transaction)
    }
    
    // MARK: - Transfer Between Users (Transacción Atómica)
    
    func transferBetweenUsers(
        fromCardId: String,
        fromUserId: String,
        toCardId: String,
        toUserId: String,
        amount: Double,
        description: String
    ) async throws {
        
        // Usar transacción atómica de Firestore
        try await db.runTransaction({ (transaction, errorPointer) -> Any? in
            // Referencias
            let fromCardRef = self.db.collection("users").document(fromUserId).collection("cards").document(fromCardId)
            let toCardRef = self.db.collection("users").document(toUserId).collection("cards").document(toCardId)
            
            // Leer datos actuales
            let fromCardSnapshot: DocumentSnapshot
            let toCardSnapshot: DocumentSnapshot
            
            do {
                fromCardSnapshot = try transaction.getDocument(fromCardRef)
                toCardSnapshot = try transaction.getDocument(toCardRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard var fromCard = try? fromCardSnapshot.data(as: Card.self),
                  var toCard = try? toCardSnapshot.data(as: Card.self) else {
                let error = NSError(domain: "CardRepository", code: -1,
                                   userInfo: [NSLocalizedDescriptionKey: "No se pudieron leer las tarjetas"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Validar saldo suficiente
            guard fromCard.balance >= amount else {
                let error = NSError(domain: "CardRepository", code: -2,
                                   userInfo: [NSLocalizedDescriptionKey: "Saldo insuficiente"])
                errorPointer?.pointee = error
                return nil
            }
            
            // Actualizar balances
            fromCard.balance -= amount
            toCard.balance += amount
            
            // Guardar cambios
            do {
                try transaction.setData(from: fromCard, forDocument: fromCardRef, merge: true)
                try transaction.setData(from: toCard, forDocument: toCardRef, merge: true)
            } catch let updateError as NSError {
                errorPointer?.pointee = updateError
                return nil
            }
            
            return nil
        })
        
        // Después de la transacción exitosa, registrar movimientos
        let fromTransaction = Transaction(
            cardId: fromCardId,
            type: .transfer,
            amount: amount,
            description: description,
            icon: "arrow.up.right.circle.fill",
            relatedUserId: toUserId
        )
        
        let toTransaction = Transaction(
            cardId: toCardId,
            type: .received,
            amount: amount,
            description: description,
            icon: "arrow.down.circle.fill",
            relatedUserId: fromUserId
        )
        
        // Guardar transacciones (sin actualizar balance ya que se hizo arriba)
        try await saveTransactionWithoutBalanceUpdate(fromTransaction, userId: fromUserId)
        try await saveTransactionWithoutBalanceUpdate(toTransaction, userId: toUserId)
    }
    
    // MARK: - Private Methods
    
    private func updateCardBalance(cardId: String, userId: String, transaction: Transaction) async throws {
        let cardRef = db.collection("users").document(userId).collection("cards").document(cardId)
        let cardDoc = try await cardRef.getDocument()
        
        guard var card = try? cardDoc.data(as: Card.self) else {
            throw NSError(domain: "CardRepository", code: -1, userInfo: [NSLocalizedDescriptionKey: "Card not found"])
        }
        
        // Actualizar balance según tipo
        switch transaction.type {
        case .deposit, .received:
            card.balance += transaction.amount
        case .withdraw, .transfer, .payment:
            card.balance -= transaction.amount
        }
        
        try await cardRef.updateData(["balance": card.balance])
    }
    
    private func saveTransactionWithoutBalanceUpdate(_ transaction: Transaction, userId: String) async throws {
        let transactionRef = db.collection("users")
            .document(userId)
            .collection("cards")
            .document(transaction.cardId)
            .collection("transactions")
            .document(transaction.id)
        
        try transactionRef.setData(from: transaction)
    }
}
