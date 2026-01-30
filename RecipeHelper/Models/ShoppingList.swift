//
//  ShoppingList.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import SwiftData

@Model
class ShoppingListItem {
    @Attribute(.unique) var id: UUID
    var ingredientName: String
    var quantity: Double
    var unit: String
    var isPurchased: Bool
    var addedDate: Date
    var recipeName: String? // из какого рецепта добавлен
    
    init(ingredientName: String, quantity: Double, unit: String, recipeName: String? = nil) {
        self.id = UUID()
        self.ingredientName = ingredientName
        self.quantity = quantity
        self.unit = unit
        self.isPurchased = false
        self.addedDate = Date()
        self.recipeName = recipeName
    }
}
