//
//  Card.swift
//  bankapp
//
//  Created by Gerardo Gomez Schekaiban on 16/11/25.
//

import Foundation

struct Card: Identifiable, Codable {
    let id: String
    let userId: String
    let cardNumber: String // Número completo de 16 dígitos
    let cardHolderName: String
    let cardType: CardType
    var balance: Double
    let currency: String
    let createdAt: Date
    let color: String
    
    enum CardType: String, Codable, CaseIterable {
        case debit = "Débito"
        case credit = "Crédito"
        case savings = "Ahorros"
    }
    
    init(
        id: String = UUID().uuidString,
        userId: String,
        cardNumber: String,
        cardHolderName: String,
        cardType: CardType,
        balance: Double = 0.0,
        currency: String = "MXN",
        createdAt: Date = Date(),
        color: String = "blue"
    ) {
        self.id = id
        self.userId = userId
        self.cardNumber = cardNumber
        self.cardHolderName = cardHolderName
        self.cardType = cardType
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.color = color
    }
    
    // Formatear número de tarjeta (XXXX XXXX XXXX XXXX)
    var formattedCardNumber: String {
        let digits = cardNumber
        return stride(from: 0, to: min(digits.count, 16), by: 4)
            .map { i -> String in
                let start = digits.index(digits.startIndex, offsetBy: i)
                let end = digits.index(start, offsetBy: min(4, digits.count - i))
                return String(digits[start..<end])
            }
            .joined(separator: " ")
    }
    
    // Últimos 4 dígitos
    var lastFourDigits: String {
        String(cardNumber.suffix(4))
    }
    
    // Formatear balance
    var formattedBalance: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: balance)) ?? "$0.00"
    }
}
