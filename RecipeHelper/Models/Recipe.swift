//
//  Recipe.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import SwiftData

@Model
class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var recipeDescription: String
    var preparationTime: Int // в минутах
    var difficulty: DifficultyLevel
    var servings: Int
    var imageURL: String?
    
    // Пищевая информация
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fat: Double?
    
    // Категории и диеты
    var cuisineType: String? // например: "Итальянская", "Азиатская"
    var dietaryTags: [String] // например: ["vegetarian", "gluten-free"]
    var allergens: [String] // список аллергенов в рецепте
    
    // Связь с ингредиентами
    @Relationship(deleteRule: .cascade)
    var ingredients: [RecipeIngredient]?
    
    // Инструкции по приготовлению
    var instructions: [String] // массив шагов приготовления
    
    init(
        title: String,
        description: String,
        preparationTime: Int,
        difficulty: DifficultyLevel,
        servings: Int,
        instructions: [String],
        imageURL: String? = nil,
        dietaryTags: [String] = [],
        allergens: [String] = []
    ) {
        self.id = UUID()
        self.title = title
        self.recipeDescription = description
        self.preparationTime = preparationTime
        self.difficulty = difficulty
        self.servings = servings
        self.instructions = instructions
        self.imageURL = imageURL
        self.dietaryTags = dietaryTags
        self.allergens = allergens
        self.ingredients = []
    }
}

enum DifficultyLevel: String, Codable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}
