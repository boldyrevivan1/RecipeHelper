//
//  Product.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import SwiftData
import SwiftUI

enum ProductQuantityStatus: String, Codable {
    case plenty = "Plenty"
    case medium = "Medium"
    case runningOut = "Running Out"
    
    
    var icon: String {
        switch self {
        case .plenty: return "checkmark.circle.fill"
        case .medium: return "minus.circle.fill"
        case .runningOut: return "exclamationmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .plenty: return .green
        case .medium: return .orange
        case .runningOut: return .red
        }
    }
}

@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var quantityStatus: ProductQuantityStatus
    var expirationDate: Date?
    var addedDate: Date
    var category: String? // например: "Овощи", "Мясо", "Молочное"
    
    // Связь с пользователем
    var user: User?
    
    init(name: String, quantityStatus: ProductQuantityStatus, expirationDate: Date? = nil, category: String? = nil) {
        self.id = UUID()
        self.name = name
        self.quantityStatus = quantityStatus
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
