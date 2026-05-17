import Foundation
import SwiftData

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var recipeDescription: String
    var preparationTime: Int
    var difficulty: DifficultyLevel
    var servings: Int
    var instructions: [String]
    var imageURL: String?
    var cuisineType: String?
    var dietaryTags: [String]?
    var allergens: [String]?
    var isFavorite: Bool = false

    @Relationship(deleteRule: .cascade) var ingredients: [RecipeIngredient]?

    init(title: String, recipeDescription: String, preparationTime: Int, difficulty: DifficultyLevel, servings: Int, instructions: [String], imageURL: String? = nil, dietaryTags: [String]? = nil, allergens: [String]? = nil) {
        self.id = UUID()
        self.title = title
        self.recipeDescription = recipeDescription
        self.preparationTime = preparationTime
        self.difficulty = difficulty
        self.servings = servings
        self.instructions = instructions
        self.imageURL = imageURL
        self.dietaryTags = dietaryTags
        self.allergens = allergens
        self.isFavorite = false
    }
}

enum DifficultyLevel: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}
