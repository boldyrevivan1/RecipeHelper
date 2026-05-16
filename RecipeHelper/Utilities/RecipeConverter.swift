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
        let instructions: [String] = {
            guard let raw = meal.strInstructions else { return [] }
            // MealDB sometimes uses \r\n, sometimes \n, sometimes numbered paragraphs
            let lines = raw
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { line in
                    guard !line.isEmpty else { return false }
                    // Drop lines that are just a number (paragraph separators)
                    if Int(line) != nil { return false }
                    // Drop very short lines (1-2 chars)
                    if line.count <= 2 { return false }
                    return true
                }
                // Strip leading step numbers like "1." "1)" "Step 1:"
                .map { line -> String in
                    let stripped = line
                        .replacingOccurrences(of: #"^(Step\s*)?\d+[\.\):\s]\s*"#,
                                              with: "",
                                              options: .regularExpression)
                    return stripped.isEmpty ? line : stripped
                }
            return lines.isEmpty ? ["Instructions not available"] : lines
        }()
        
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
            recipeDescription: meal.strCategory ?? "No description",
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
