import Foundation
import SwiftData

@Model
final class RecipeIngredient {
    @Attribute(.unique) var id: UUID
    var ingredientName: String
    var quantity: Double
    var unit: String
    var isOptional: Bool

    var recipe: Recipe?

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
