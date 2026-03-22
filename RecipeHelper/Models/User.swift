//
//  User.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    var username: String
    var email: String
    var createdAt: Date
    
    // Связь с профилем
    @Relationship(deleteRule: .cascade)
    var profile: Profile?
    
    // Связь с продуктами
    @Relationship(deleteRule: .cascade)
    var products: [Product]?
    
    init(username: String, email: String) {
        self.id = UUID()
        self.username = username
        self.email = email
        self.createdAt = Date()
        self.products = []
    }
}

@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    
    // Диетические предпочтения
    var dietaryPreferences: [String] // например: ["vegetarian", "halal"]
    var allergies: [String] // список аллергенов
    var calorieLimit: Int? // дневной лимит калорий
    
    // Связь с пользователем
    var user: User?
    
    init(dietaryPreferences: [String] = [], allergies: [String] = [], calorieLimit: Int? = nil) {
        self.id = UUID()
        self.dietaryPreferences = dietaryPreferences
        self.allergies = allergies
        self.calorieLimit = calorieLimit
    }
}
