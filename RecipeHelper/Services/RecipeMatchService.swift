//
//  RecipeMatchService.swift
//  RecipeHelper
//

import Foundation

struct RecipeMatch {
    let recipe:             Recipe
    let matchPercentage:    Double
    let availableCount:     Int
    let totalCount:         Int
    let missingIngredients: [String]

    var canCook:    Bool { matchPercentage >= 100 }
    var matchCount: Int  { availableCount }
}

class RecipeMatchService {

    // Ingredients we always consider «available» regardless of inventory.
    // Water is on tap, we don't track it; salt/sugar/pepper live in Pantry.
    private static let ignoredIngredients: Set<String> = [
        "water", "hot water", "cold water", "warm water", "boiling water",
        "ice water", "tap water", "вода"
    ]

    /// Ингредиент, который не нужно ни проверять в инвентаре, ни добавлять в shopping list,
    /// ни списывать при готовке (например, вода).
    static func isIgnored(_ ingredientName: String) -> Bool {
        let n = ingredientName.lowercased().trimmingCharacters(in: .whitespaces)
        return ignoredIngredients.contains(n)
    }

    /// Ингредиент есть в специях (Pantry) и тогглер включён.
    static func isInPantry(_ ingredientName: String, pantry: [FSPantryItem]) -> Bool {
        let target = ingredientName.lowercased().trimmingCharacters(in: .whitespaces)
        return pantry.contains { item in
            guard item.isAvailable else { return false }
            let n = item.name.lowercased().trimmingCharacters(in: .whitespaces)
            return n == target || n.contains(target) || target.contains(n)
        }
    }

    static func findMatchingRecipes(
        recipes:   [Recipe],
        inventory: [FSProduct],
        pantry:    [FSPantryItem] = []
    ) -> [RecipeMatch] {
        recipes.map { recipe in
            calculateMatch(recipe: recipe, inventory: inventory, pantry: pantry)
        }
        .sorted { $0.matchPercentage > $1.matchPercentage }
    }

    static func calculateMatch(
        recipe:    Recipe,
        inventory: [FSProduct],
        pantry:    [FSPantryItem] = []
    ) -> RecipeMatch {
        guard let allIngredients = recipe.ingredients, !allIngredients.isEmpty else {
            return RecipeMatch(recipe: recipe, matchPercentage: 0,
                               availableCount: 0, totalCount: 0, missingIngredients: [])
        }

        // Исключаем и воду, и специи из pantry — это ингредиенты, которые
        // у пользователя заведомо есть, в процент совпадения их включать
        // не нужно (иначе любой рецепт с большим количеством базовых специй
        // автоматически «доступен» даже при пустом холодильнике).
        let ingredients = allIngredients.filter {
            !isIgnored($0.ingredientName)
            && !isInPantry($0.ingredientName, pantry: pantry)
        }

        guard !ingredients.isEmpty else {
            return RecipeMatch(recipe: recipe, matchPercentage: 100,
                               availableCount: 0, totalCount: 0, missingIngredients: [])
        }

        var available = 0
        var missing:   [String] = []

        for ingredient in ingredients {
            if isAvailable(ingredient.ingredientName, in: inventory) {
                available += 1
            } else {
                missing.append(ingredient.ingredientName)
            }
        }

        let total      = ingredients.count
        let percentage = total > 0 ? Double(available) / Double(total) * 100 : 0

        return RecipeMatch(
            recipe:             recipe,
            matchPercentage:    percentage,
            availableCount:     available,
            totalCount:         total,
            missingIngredients: missing
        )
    }

    private static func isAvailable(_ ingredientName: String, in inventory: [FSProduct]) -> Bool {
        let lower = ingredientName.lowercased().trimmingCharacters(in: .whitespaces)
        return inventory.contains { product in
            let name = product.name.lowercased().trimmingCharacters(in: .whitespaces)
            if name == lower || name.contains(lower) || lower.contains(name) { return true }
            if areSynonyms(lower, name) { return true }
            return false
        }
    }

    /// Small built-in synonym list so that e.g. "pasta" matches "spaghetti"
    /// in the inventory, and "tomatoes" in a recipe matches "tomato" in stock.
    /// This list is intentionally tiny — for anything bigger we'd need a real
    /// ingredient ontology. Kept static so it can be reused across the app.
    static func areSynonyms(_ a: String, _ b: String) -> Bool {
        let groups: [Set<String>] = [
            ["tomato", "tomatoes"],
            ["onion", "onions"],
            ["potato", "potatoes"],
            ["chicken", "chicken breast", "chicken thigh", "chicken thighs"],
            ["pasta", "spaghetti", "penne", "fettuccine", "linguine", "tagliatelle"],
            ["cheese", "cheddar", "mozzarella", "parmesan", "pecorino"],
            ["egg", "eggs"],
            ["lemon", "lemons"],
            ["pepper", "bell pepper", "bell peppers"],
            ["bacon", "pancetta"],
        ]
        for g in groups where g.contains(a) && g.contains(b) { return true }
        return false
    }
}
