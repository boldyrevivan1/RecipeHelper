//
//  RecipeDetailView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

//
//  RecipeDetailView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//



import SwiftUI
import SwiftData

struct CookingSessionItem: Identifiable { let id: UUID }

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let recipe: Recipe

    @State private var showAddedAlert   = false
    @State private var addedItemsCount  = 0
    @State private var isLoadingDetail  = false
    @State private var cookingSessionItem: CookingSessionItem? = nil
    @ObservedObject private var cookingManager = CookingSessionManager.shared

    private let mealDBService = MealDBService.shared
    
    // Check if this recipe needs detail loading
    private var needsDetailLoad: Bool {
        let hasIngredients = !(recipe.ingredients?.isEmpty ?? true)
        let hasInstructions = !(recipe.instructions.isEmpty)
        return !hasIngredients || !hasInstructions
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Recipe Image
                if let imageURL = recipe.imageURL {
                    CachedAsyncImage(url: imageURL) { image in
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
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                    
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

                            Spacer(minLength: 8)

                            // Match indicator
                            let match = calculateMatch()
                            HStack(spacing: 4) {
                                Image(systemName: match.percentage >= 70 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                    .foregroundStyle(match.percentage >= 70 ? .green : .orange)
                                Text("\(match.available)/\(match.total)")
                                    .font(.caption).fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                            }
                            .lineLimit(1)
                            .fixedSize()
                        }

                        if let ingredients = recipe.ingredients {
                            let pantry = FirestoreService.shared.pantry
                            ForEach(
                                ingredients.filter {
                                    !RecipeMatchService.isIgnored($0.ingredientName)
                                    && !RecipeMatchService.isInPantry($0.ingredientName, pantry: pantry)
                                },
                                id: \.id
                            ) { recipeIngredient in
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
                    
                    // Start Cooking button — disabled until user has every
                    // non-pantry ingredient in stock (water and pantry spices
                    // are automatically excluded, see isIngredientAvailable).
                    let canCook = !hasMissingIngredients()
                    Button {
                        let session = cookingManager.startSession(recipe: recipe)
                        cookingSessionItem = CookingSessionItem(id: session.id)
                    } label: {
                        HStack {
                            Image(systemName: canCook ? "flame.fill" : "lock.fill")
                            Text(canCook ? "Start Cooking" : "Missing ingredients")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(canCook ? Color.orange : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .disabled(!canCook)
                    .padding(.vertical, 8)

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
        .safeAreaInset(edge: .bottom) {
            if !CookingSessionManager.shared.sessions.isEmpty {
                Color.clear.frame(height: 70)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: recipe.isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(recipe.isFavorite ? .red : .gray)
                        .font(.title2)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if needsDetailLoad && !isLoadingDetail {
                await loadDetail()
            }
        }
        .overlay {
            if isLoadingDetail {
                ProgressView("Loading recipe...")
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
            }
        }
        .sheet(item: $cookingSessionItem) { item in
            CookingSessionView(recipe: recipe, sessionId: item.id)
        }
        .alert("Added to Shopping List", isPresented: $showAddedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Added \(addedItemsCount) missing ingredients to your shopping list")
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateMatch() -> (percentage: Double, available: Int, total: Int) {
        guard let all = recipe.ingredients, !all.isEmpty else { return (0, 0, 0) }
        let pantry = FirestoreService.shared.pantry
        // Exclude both "always-free" ingredients (water) AND spices the user has
        // in pantry — they shouldn't be part of the denominator either.
        let ingredients = all.filter {
            !RecipeMatchService.isIgnored($0.ingredientName)
            && !RecipeMatchService.isInPantry($0.ingredientName, pantry: pantry)
        }
        guard !ingredients.isEmpty else { return (100, 0, 0) }
        let available = ingredients.filter { isIngredientAvailable($0) }.count
        let total = ingredients.count
        let percentage = (Double(available) / Double(total)) * 100.0
        return (percentage, available, total)
    }
    
    private func isIngredientAvailable(_ recipeIngredient: RecipeIngredient) -> Bool {
        let name = recipeIngredient.ingredientName
        if RecipeMatchService.isIgnored(name) { return true }   // water, etc.
        if RecipeMatchService.isInPantry(name, pantry: FirestoreService.shared.pantry) { return true }

        let ingredientName = name.lowercased().trimmingCharacters(in: .whitespaces)
        let inventory = FirestoreService.shared.products
        for product in inventory {
            let n = product.name.lowercased().trimmingCharacters(in: .whitespaces)
            if n == ingredientName || n.contains(ingredientName) || ingredientName.contains(n) { return true }
            if RecipeMatchService.areSynonyms(ingredientName, n) { return true }
        }
        return false
    }

    private func hasMissingIngredients() -> Bool {
        guard let ingredients = recipe.ingredients else { return false }
        return ingredients.contains { !isIngredientAvailable($0) }
    }
    
    private func addMissingToShoppingList() {
        guard let ingredients = recipe.ingredients else { return }
        let fs = FirestoreService.shared
        var addedCount = 0
        Task {
            for recipeIngredient in ingredients {
                if !isIngredientAvailable(recipeIngredient) {
                    let alreadyInList = fs.shoppingList.contains {
                        $0.ingredientName.lowercased() == recipeIngredient.ingredientName.lowercased()
                    }
                    if !alreadyInList {
                        let item = FSShoppingItem(
                            ingredientName: recipeIngredient.ingredientName,
                            quantity: recipeIngredient.quantity,
                            unit: recipeIngredient.unit,
                            isPurchased: false,
                            addedDate: Date(),
                            recipeName: recipe.title
                        )
                        try? await fs.addShoppingItem(item)
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
    private func toggleFavorite() {
        recipe.isFavorite.toggle()
    }

    // MARK: - Lazy detail loading

    private func loadDetail() async {
        guard needsDetailLoad else { return }
        isLoadingDetail = true
        defer { isLoadingDetail = false }
        do {
            let results = try await mealDBService.searchMeals(query: recipe.title)
            guard let match = results.first(where: { $0.strMeal == recipe.title }),
                  let full  = try await mealDBService.getMealDetails(id: match.idMeal)
            else { return }
            await MainActor.run {
                recipe.cuisineType     = full.strArea
                recipe.preparationTime = 30
                let ingredients = full.getIngredients()
                let recipeIngredients: [RecipeIngredient] = ingredients.map { name, measure in
                    let ri = RecipeIngredient(ingredientName: name, quantity: 1.0, unit: measure, isOptional: false)
                    ri.recipe = recipe
                    modelContext.insert(ri)
                    return ri
                }
                recipe.ingredients = recipeIngredients
                let instructions = full.strInstructions?
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty && Int($0) == nil && $0.count > 2 }
                    .map { $0.replacingOccurrences(of: #"^(Step\s*)?\d+[\.\):\s]\s*"#, with: "", options: .regularExpression) }
                    ?? []
                recipe.instructions = instructions
            }
        } catch {
            print("Failed to load recipe detail: \(error)")
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
                
                // Show unit/measure only — quantity is always 1.0 from MealDB
                if !recipeIngredient.unit.isEmpty {
                    Text(recipeIngredient.unit)
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
            recipeDescription: "Classic Italian pasta",
            preparationTime: 30,
            difficulty: .medium,
            servings: 4,
            instructions: ["Boil pasta", "Cook bacon", "Mix eggs", "Combine all"],
            imageURL: nil,
            dietaryTags: [],
            allergens: []
        ))
    }
    .modelContainer(for: [Recipe.self, RecipeIngredient.self], inMemory: true)
}
