//
//  RecipeDetailView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//



import SwiftUI
import SwiftData

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var inventory: [Product]
    @Query private var shoppingList: [ShoppingListItem]
    
    let recipe: Recipe
    
    @State private var showAddedAlert = false
    @State private var addedItemsCount = 0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe Image
                if let imageURL = recipe.imageURL {
                    AsyncImage(url: URL(string: imageURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 0))
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(recipe.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    // Metadata
                    HStack(spacing: 16) {
                        Label("\(recipe.preparationTime) min", systemImage: "clock")
                        Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    // Cuisine Type
                    if let cuisine = recipe.cuisineType {
                        Text(cuisine)
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    // Ingredients with availability indicator
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            // Match indicator
                            let match = calculateMatch()
                            HStack(spacing: 4) {
                                Image(systemName: match.percentage >= 70 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundStyle(match.percentage >= 70 ? .green : .orange)
                                Text("\(Int(match.percentage))% available")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        if let ingredients = recipe.ingredients {
                            ForEach(ingredients, id: \.id) { recipeIngredient in
                                IngredientRowView(
                                    recipeIngredient: recipeIngredient,
                                    isAvailable: isIngredientAvailable(recipeIngredient)
                                )
                            }
                        }
                    }
                    
                    // Add to Shopping List Button
                    if hasMissingIngredients() {
                        Button {
                            addMissingToShoppingList()
                        } label: {
                            HStack {
                                Image(systemName: "cart.badge.plus")
                                Text("Add Missing to Shopping List")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.vertical, 8)
                    }
                    
                    Divider()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 28, height: 28)
                                    .background(Color.blue)
                                    .clipShape(Circle())
                                
                                Text(instruction)
                                    .font(.body)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("Added to Shopping List", isPresented: $showAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Added \(addedItemsCount) missing ingredients to your shopping list")
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateMatch() -> (percentage: Double, available: Int, total: Int) {
        guard let ingredients = recipe.ingredients, !ingredients.isEmpty else {
            return (0, 0, 0)
        }
        
        let available = ingredients.filter { isIngredientAvailable($0) }.count
        let total = ingredients.count
        let percentage = (Double(available) / Double(total)) * 100.0
        
        return (percentage, available, total)
    }
    
    private func isIngredientAvailable(_ recipeIngredient: RecipeIngredient) -> Bool {
        let ingredientName = recipeIngredient.ingredientName.lowercased().trimmingCharacters(in: .whitespaces)
        
        for product in inventory {
            let productName = product.name.lowercased().trimmingCharacters(in: .whitespaces)
            
            // Точное совпадение
            if productName == ingredientName {
                return true
            }
            
            // Частичное совпадение
            if productName.contains(ingredientName) || ingredientName.contains(productName) {
                return true
            }
            
            // Синонимы (упрощенно)
            if areSynonyms(ingredientName, productName) {
                return true
            }
        }
        
        return false
    }
    
    private func areSynonyms(_ word1: String, _ word2: String) -> Bool {
        let synonyms: [String: [String]] = [
            "tomato": ["tomatoes"],
            "onion": ["onions"],
            "chicken": ["chicken breast", "chicken thigh"],
            "pasta": ["spaghetti", "penne"],
            "cheese": ["cheddar", "mozzarella"]
        ]
        
        for (key, values) in synonyms {
            if (word1 == key && values.contains(word2)) ||
               (word2 == key && values.contains(word1)) ||
               (values.contains(word1) && values.contains(word2)) {
                return true
            }
        }
        
        return false
    }
    
    private func hasMissingIngredients() -> Bool {
        guard let ingredients = recipe.ingredients else { return false }
        return ingredients.contains { !isIngredientAvailable($0) }
    }
    
    private func addMissingToShoppingList() {
        guard let ingredients = recipe.ingredients else { return }
        
        var addedCount = 0
        
        for recipeIngredient in ingredients {
            // Проверяем что ингредиента нет в инвентаре
            if !isIngredientAvailable(recipeIngredient) {
                // Проверяем что еще не добавлен в список покупок
                let alreadyInList = shoppingList.contains { item in
                    item.ingredientName.lowercased() == recipeIngredient.ingredientName.lowercased()
                }
                
                if !alreadyInList {
                    let shoppingItem = ShoppingListItem(
                        ingredientName: recipeIngredient.ingredientName,
                        quantity: recipeIngredient.quantity,
                        unit: recipeIngredient.unit,
                        recipeName: recipe.title
                    )
                    
                    modelContext.insert(shoppingItem)
                    addedCount += 1
                }
            }
        }
        
        if addedCount > 0 {
            addedItemsCount = addedCount
            showAddedAlert = true
        }
    }
}

// MARK: - Ingredient Row

struct IngredientRowView: View {
    let recipeIngredient: RecipeIngredient
    let isAvailable: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Availability indicator
            Image(systemName: isAvailable ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isAvailable ? .green : .gray.opacity(0.3))
                .font(.title3)
            
            // Ingredient info
            VStack(alignment: .leading, spacing: 2) {
                Text(recipeIngredient.ingredientName)
                    .font(.body)
                    .strikethrough(isAvailable, color: .secondary)
                    .foregroundStyle(isAvailable ? .secondary : .primary)
                
                if recipeIngredient.quantity > 0 {
                    Text("\(String(format: "%.1f", recipeIngredient.quantity)) \(recipeIngredient.unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            if !isAvailable {
                Text("Need")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundStyle(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(recipe: Recipe(
            title: "Spaghetti Carbonara",
            description: "Classic Italian pasta",
            preparationTime: 30,
            difficulty: .medium,
            servings: 4,
            instructions: ["Boil pasta", "Cook bacon", "Mix eggs", "Combine all"],
            imageURL: nil,
            dietaryTags: [],
            allergens: []
        ))
    }
    .modelContainer(for: [Product.self, ShoppingListItem.self], inMemory: true)
}
