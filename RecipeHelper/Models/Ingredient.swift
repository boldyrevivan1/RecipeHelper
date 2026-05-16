//
//  Ingredient.swift
//  RecipeHelper
//
//  SwiftData model for a single line of ingredients inside a Recipe
//  (name + quantity + unit). The parent `Recipe` owns the list.
//

import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var ingredientName: String
    var quantity: Double
    var unit: String
    var isOptional: Bool

    // Relationship to parent recipe
    var recipe: Recipe?

    // Possible substitutes (unused for now, kept for compatibility)
    var substitutes: [String]?

    init(ingredientName: String, quantity: Double, unit: String,
         isOptional: Bool = false, substitutes: [String]? = nil) {
        self.id             = UUID()
        self.ingredientName = ingredientName
        self.quantity       = quantity
        self.unit           = unit
        self.isOptional     = isOptional
        self.substitutes    = substitutes
    }
}
