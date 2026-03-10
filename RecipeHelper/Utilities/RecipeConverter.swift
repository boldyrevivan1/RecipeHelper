//
//  RecipeConverter.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 08.02.2026.
//

import Foundation
import SwiftData

class RecipeConverter {
    @MainActor
    static func convertMealDTOToRecipe(meal: MealDTO, modelContext: ModelContext) -> Recipe {
        // Разбиваем инструкции на шаги
        let instructions = meal.strInstructions?
            .components(separatedBy: "\r\n")
            .filter { !$0.isEmpty }
            .map { $0.trimmingCharacters(in: .whitespaces) } ?? []
        
        // Определяем сложность (упрощенная логика)
        let difficulty: DifficultyLevel
        let ingredientsCount = meal.getIngredients().count
        if ingredientsCount <= 5 {
            difficulty = .easy
        } else if ingredientsCount <= 10 {
            difficulty = .medium
        } else {
            difficulty = .hard
        }
        
        // Создаем рецепт
        let recipe = Recipe(
            title: meal.strMeal,
            description: meal.strCategory ?? "No description",
            preparationTime: 30, // По умолчанию, так как API не предоставляет
            difficulty: difficulty,
            servings: 4, // По умолчанию
            instructions: instructions.isEmpty ? ["Instructions not available"] : instructions,
            imageURL: meal.strMealThumb,
            dietaryTags: meal.strTags?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            allergens: []
        )
        
        recipe.cuisineType = meal.strArea
        
        // Создаем ингредиенты
        let ingredientsList = meal.getIngredients()
        var recipeIngredients: [RecipeIngredient] = []
        
        for (ingredient, measure) in ingredientsList {
            let recipeIngredient = RecipeIngredient(
                ingredientName: ingredient,
                quantity: 1.0, // Упрощенно
                unit: measure,
                isOptional: false
            )
            recipeIngredient.recipe = recipe
            recipeIngredients.append(recipeIngredient)
            modelContext.insert(recipeIngredient)
        }
        
        recipe.ingredients = recipeIngredients
        
        return recipe
    }
}
