//
//  Product.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import SwiftData

@Model
class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantity: Double
    var unit: String // например: "kg", "l", "шт"
    var expirationDate: Date?
    var addedDate: Date
    var category: String? // например: "Овощи", "Мясо", "Молочное"
    
    // Связь с пользователем
    var user: User?
    
    init(name: String, quantity: Double, unit: String, expirationDate: Date? = nil, category: String? = nil) {
        self.id = UUID()
        self.name = name
        self.quantity = quantity
        self.unit = unit
        self.expirationDate = expirationDate
        self.addedDate = Date()
        self.category = category
    }
    
    // Проверка, истек ли срок годности
    var isExpired: Bool {
        guard let expirationDate = expirationDate else { return false }
        return expirationDate < Date()
    }
    
    // Проверка, скоро ли истечет срок (в течение 3 дней)
    var isExpiringSoon: Bool {
        guard let expirationDate = expirationDate else { return false }
        let threeDaysFromNow = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        return expirationDate <= threeDaysFromNow && expirationDate >= Date()
    }
}
