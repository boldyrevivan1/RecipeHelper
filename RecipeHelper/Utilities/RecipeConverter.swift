import Foundation
import SwiftData

class RecipeConverter {
    @MainActor
    static func convertMealDTOToRecipe(meal: MealDTO, modelContext: ModelContext) -> Recipe {

        let instructions: [String] = {
            guard let raw = meal.strInstructions else { return [] }

            let lines = raw
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { line in
                    guard !line.isEmpty else { return false }

                    if Int(line) != nil { return false }

                    if line.count <= 2 { return false }
                    return true
                }

                .map { line -> String in
                    let stripped = line
                        .replacingOccurrences(of: #"^(Step\s*)?\d+[\.\):\s]\s*"#,
                                              with: "",
                                              options: .regularExpression)
                    return stripped.isEmpty ? line : stripped
                }
            return lines.isEmpty ? ["Instructions not available"] : lines
        }()

        let difficulty: DifficultyLevel
        let ingredientsCount = meal.getIngredients().count
        if ingredientsCount <= 5 {
            difficulty = .easy
        } else if ingredientsCount <= 10 {
            difficulty = .medium
        } else {
            difficulty = .hard
        }

        let recipe = Recipe(
            title: meal.strMeal,
            recipeDescription: meal.strCategory ?? "No description",
            preparationTime: 30,
            difficulty: difficulty,
            servings: 4,
            instructions: instructions.isEmpty ? ["Instructions not available"] : instructions,
            imageURL: meal.strMealThumb,
            dietaryTags: meal.strTags?.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) } ?? [],
            allergens: []
        )

        recipe.cuisineType = meal.strArea

        let ingredientsList = meal.getIngredients()
        var recipeIngredients: [RecipeIngredient] = []

        for (ingredient, measure) in ingredientsList {
            let recipeIngredient = RecipeIngredient(
                ingredientName: ingredient,
                quantity: 1.0,
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
