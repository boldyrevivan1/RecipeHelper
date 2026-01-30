//
//  Ingredient.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import SwiftData

@Model
class Ingredient {
    @Attribute(.unique) var id: UUID
    var name: String
    var category: String? // например: "Овощи", "Специи"
    
    init(name: String, category: String? = nil) {
        self.id = UUID()
        self.name = name
        self.category = category
    }
}

@Model
class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var ingredientName: String
    var quantity: Double
    var unit: String
    var isOptional: Bool
    
    // Связь с рецептом
    var recipe: Recipe?
    
    // Возможные замены
    var substitutes: [String]? // список возможных заменителей
    
    init(ingredientName: String, quantity: Double, unit: String, isOptional: Bool = false, substitutes: [String]? = nil) {
        self.id = UUID()
        self.ingredientName = ingredientName
        self.quantity = quantity
        self.unit = unit
        self.isOptional = isOptional
        self.substitutes = substitutes
    }
}
