//
//  RecipeMatchService.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 10.03.2026.
//



import Foundation
import SwiftData

struct RecipeMatch {
    let recipe: Recipe
    let matchPercentage: Double
    let availableIngredients: [RecipeIngredient]
    let missingIngredients: [RecipeIngredient]
    
    var matchCount: Int {
        availableIngredients.count
    }
    
    var totalCount: Int {
        availableIngredients.count + missingIngredients.count
    }
    
    var canCook: Bool {
        matchPercentage >= 70.0 // Можно готовить если есть 70%+ ингредиентов
    }
}

class RecipeMatchService {
    
    // MARK: - Main Method
    
    /// Находит рецепты которые можно приготовить на основе инвентаря
    static func findMatchingRecipes(
        recipes: [Recipe],
        inventory: [Product]
    ) -> [RecipeMatch] {
        
        var matches: [RecipeMatch] = []
        
        for recipe in recipes {
            let match = calculateMatch(recipe: recipe, inventory: inventory)
            matches.append(match)
        }
        
        // Сортируем по проценту совпадения (от большего к меньшему)
        return matches.sorted { $0.matchPercentage > $1.matchPercentage }
    }
    
    // MARK: - Private Methods
    
    private static func calculateMatch(
        recipe: Recipe,
        inventory: [Product]
    ) -> RecipeMatch {
        
        guard let recipeIngredients = recipe.ingredients, !recipeIngredients.isEmpty else {
            return RecipeMatch(
                recipe: recipe,
                matchPercentage: 0,
                availableIngredients: [],
                missingIngredients: []
            )
        }
        
        var available: [RecipeIngredient] = []
        var missing: [RecipeIngredient] = []
        
        for recipeIngredient in recipeIngredients {
            if isIngredientAvailable(recipeIngredient, in: inventory) {
                available.append(recipeIngredient)
            } else {
                missing.append(recipeIngredient)
            }
        }
        
        let totalIngredients = recipeIngredients.count
        let matchPercentage = totalIngredients > 0
            ? (Double(available.count) / Double(totalIngredients)) * 100.0
            : 0.0
        
        return RecipeMatch(
            recipe: recipe,
            matchPercentage: matchPercentage,
            availableIngredients: available,
            missingIngredients: missing
        )
    }
    
    private static func isIngredientAvailable(
        _ recipeIngredient: RecipeIngredient,
        in inventory: [Product]
    ) -> Bool {
        
        // Используем название ингредиента напрямую
        let ingredientName = recipeIngredient.ingredientName.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Ищем точное совпадение или частичное
        for product in inventory {
            let productName = product.name.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Точное совпадение
            if productName == ingredientName {
                return true
            }
            
            // Частичное совпадение (например: "chicken breast" содержит "chicken")
            if productName.contains(ingredientName) || ingredientName.contains(productName) {
                return true
            }
            
            // Проверка синонимов
            if areSynonyms(ingredientName, productName) {
                return true
            }
        }
        
        return false
    }
    
    private static func areSynonyms(_ word1: String, _ word2: String) -> Bool {
        // Словарь синонимов (можно расширить)
        let synonyms: [String: [String]] = [
            "tomato": ["tomatoes", "tomato sauce"],
            "onion": ["onions", "shallot", "shallots"],
            "garlic": ["garlic clove", "garlic cloves"],
            "chicken": ["chicken breast", "chicken thigh", "chicken drumstick"],
            "beef": ["beef steak", "ground beef", "beef mince"],
            "pasta": ["spaghetti", "penne", "fusilli", "macaroni"],
            "rice": ["white rice", "brown rice", "basmati rice"],
            "milk": ["whole milk", "skim milk", "2% milk"],
            "cheese": ["cheddar", "mozzarella", "parmesan"],
            "butter": ["margarine", "unsalted butter"],
            "oil": ["olive oil", "vegetable oil", "cooking oil"],
            "salt": ["sea salt", "table salt", "kosher salt"],
            "pepper": ["black pepper", "white pepper", "ground pepper"]
        ]
        
        // Проверяем в обе стороны
        for (key, values) in synonyms {
            if (word1 == key && values.contains(word2)) ||
               (word2 == key && values.contains(word1)) {
                return true
            }
            
            if values.contains(word1) && values.contains(word2) {
                return true
            }
        }
        
        return false
    }
}
