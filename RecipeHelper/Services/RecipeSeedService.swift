//
//  RecipeSeedService.swift
//  RecipeHelper
//

import Foundation
import SwiftData

struct SeedRecipe: Decodable {
    let id: String
    let title: String
    let description: String
    let prepTime: Int
    let difficulty: String
    let servings: Int
    let cuisine: String
    let imageURL: String
    let tags: [String]?
    let dietaryTags: [String]?
    let allergens: [String]?
    let instructions: [String]
    let ingredients: [SeedIngredient]
}

struct SeedIngredient: Decodable {
    let name: String
    let measure: String
}

enum RecipeSeedService {

    @MainActor
    static func seedIfNeeded(modelContext: ModelContext) {
        let descriptor = FetchDescriptor<Recipe>()
        let count = (try? modelContext.fetchCount(descriptor)) ?? 0

        // Force re-seed if recipes don't have dietary tags
        if count >= 10 {
            let sample = try? modelContext.fetch(FetchDescriptor<Recipe>())
            let hasTags = sample?.first(where: { !($0.dietaryTags ?? []).isEmpty }) != nil
            if hasTags { return }

            // Delete all existing recipes to re-seed with tags
            print("🔄 Re-seeding recipes with dietary tags...")
            let allRecipes = (try? modelContext.fetch(FetchDescriptor<Recipe>())) ?? []
            for recipe in allRecipes { modelContext.delete(recipe) }
        }

        guard let url  = Bundle.main.url(forResource: "recipes", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let seeds = try? JSONDecoder().decode([SeedRecipe].self, from: data)
        else {
            print("❌ Failed to load recipes.json")
            return
        }

        for seed in seeds {
            let difficulty: DifficultyLevel
            switch seed.difficulty {
            case "Hard":   difficulty = .hard
            case "Medium": difficulty = .medium
            default:       difficulty = .easy
            }

            // Use dietaryTags if available, fallback to tags
            let dietary = seed.dietaryTags ?? seed.tags ?? []

            let recipe = Recipe(
                title:             seed.title,
                recipeDescription: seed.description,
                preparationTime:   seed.prepTime,
                difficulty:        difficulty,
                servings:          seed.servings,
                instructions:      seed.instructions,
                imageURL:          seed.imageURL.isEmpty ? nil : seed.imageURL,
                dietaryTags:       dietary,
                allergens:         seed.allergens ?? []
            )
            recipe.cuisineType = seed.cuisine

            var recipeIngredients: [RecipeIngredient] = []
            for ing in seed.ingredients {
                let ri = RecipeIngredient(
                    ingredientName: ing.name,
                    quantity: 1.0,
                    unit: ing.measure,
                    isOptional: false
                )
                ri.recipe = recipe
                recipeIngredients.append(ri)
                modelContext.insert(ri)
            }
            recipe.ingredients = recipeIngredients
            modelContext.insert(recipe)
        }

        print("✅ Seeded \(seeds.count) recipes with dietary tags")
    }
}
