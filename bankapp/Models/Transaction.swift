//
//  Transaction.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 16/11/25.
//

import Foundation

struct Transaction: Identifiable, Codable {
    let id: String
    let cardId: String
    let type: TransactionType
    let amount: Double
    let description: String
    let date: Date
    let icon: String
    // Para transferencias entre usuarios
    let relatedUserId: String?
    let relatedUserEmail: String?
    
    enum TransactionType: String, Codable {
        case deposit = "Depósito"
        case withdraw = "Retiro"
        case transfer = "Transferencia"
        case received = "Recibido"
        case payment = "Pago"
    }
    
    init(
        id: String = UUID().uuidString,
        cardId: String,
        type: TransactionType,
        amount: Double,
        description: String,
        date: Date = Date(),
        icon: String,
        relatedUserId: String? = nil,
        relatedUserEmail: String? = nil
    ) {
        self.id = id
        self.cardId = cardId
        self.type = type
        self.amount = amount
        self.description = description
        self.date = date
        self.icon = icon
        self.relatedUserId = relatedUserId
        self.relatedUserEmail = relatedUserEmail
    }
    
    // Formatear cantidad con signo
    func formattedAmount(showSign: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        let formattedValue = formatter.string(from: NSNumber(value: abs(amount))) ?? "$0.00"
        
        if !showSign {
            return formattedValue
        }
        
        switch type {
        case .deposit, .received:
            return "+\(formattedValue)"
        case .withdraw, .transfer, .payment:
            return "-\(formattedValue)"
        }
    }
    
    // Color según tipo
    var amountColor: String {
        switch type {
        case .deposit, .received:
            return "green"
        case .withdraw, .transfer, .payment:
            return "red"
        }
    }
}
