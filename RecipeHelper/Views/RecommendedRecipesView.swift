//
//  RecommendedRecipesView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 08.02.2026.
//

import SwiftUI
import SwiftData

struct RecommendedRecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Recipe.title) private var allRecipes: [Recipe]
    @Query private var inventory: [Product]
    
    @State private var recipeMatches: [RecipeMatch] = []
    @State private var isLoading = false
    @State private var loadingProgress: Double = 0.0
    @State private var loadingStatus: String = ""
    @State private var errorMessage: String?
    @State private var showError = false
    
    private let mealDBService = MealDBService.shared
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if recipeMatches.isEmpty {
                    emptyStateView
                } else {
                    recipeListView
                }
            }
            .navigationTitle("Top Recommendations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        analyzeExistingRecipes()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(allRecipes.isEmpty)
                }
            }
            .task {
                // Проверяем нужно ли загружать рецепты
                if allRecipes.count < 100 {
                    // Загружаем все рецепты параллельно (один раз)
                    await loadAllRecipesParallel()
                } else {
                    // Рецепты уже загружены - просто анализируем
                    analyzeExistingRecipes()
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView(value: loadingProgress, total: 1.0) {
                Text("Loading recipes from TheMealDB...")
                    .font(.headline)
            }
            
            Text(loadingStatus)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Text("\(Int(loadingProgress * 100))%")
                .font(.title)
                .fontWeight(.bold)
                .foregroundStyle(.blue)
            
            Text("This will take 1-2 minutes")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Loading once, then instant! ⚡")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Recipes Yet",
            systemImage: "book.closed",
            description: Text("Recipes are being loaded...")
        )
    }
    
    private var recipeListView: some View {
        List {
            Section {
                ForEach(Array(recipeMatches.prefix(10)), id: \.recipe.id) { match in
                    NavigationLink(destination: RecipeDetailView(recipe: match.recipe)) {
                        RecommendedRecipeRow(match: match)
                    }
                }
            } header: {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundStyle(.yellow)
                    Text("Top 10 Best Matches")
                        .font(.headline)
                }
            } footer: {
                if recipeMatches.count > 10 {
                    Text("Showing top 10 of \(recipeMatches.count) recipes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .refreshable {
            analyzeExistingRecipes()
        }
    }
    
    // MARK: - Methods
    
    /// Загружает ВСЕ рецепты из TheMealDB параллельно (занимает 1-2 минуты)
    private func loadAllRecipesParallel() async {
        await MainActor.run {
            isLoading = true
            loadingProgress = 0.0
            errorMessage = nil
        }
        
        do {
            // Шаг 1: Загружаем список всех категорий параллельно
            await MainActor.run {
                loadingStatus = "Loading categories..."
                loadingProgress = 0.1
            }
            
            let categories = [
                "Beef", "Chicken", "Dessert", "Lamb", "Miscellaneous",
                "Pasta", "Pork", "Seafood", "Side", "Starter",
                "Vegan", "Vegetarian", "Breakfast", "Goat"
            ]
            
            // Шаг 2: ПАРАЛЛЕЛЬНО загружаем все рецепты из всех категорий
            await MainActor.run {
                loadingStatus = "Loading all recipes from \(categories.count) categories..."
                loadingProgress = 0.2
            }
            
            let allMealsArrays = await withTaskGroup(of: [MealDTO].self) { group in
                for category in categories {
                    group.addTask {
                        (try? await self.mealDBService.getMealsByCategory(category: category)) ?? []
                    }
                }
                
                var results: [[MealDTO]] = []
                for await mealsArray in group {
                    results.append(mealsArray)
                }
                return results
            }
            
            let allMeals = allMealsArrays.flatMap { $0 }
            var loadedMealIds: Set<String> = Set()
            
            await MainActor.run {
                loadingStatus = "Found \(allMeals.count) recipes! Loading details..."
                loadingProgress = 0.3
            }
            
            // Шаг 3: ПАРАЛЛЕЛЬНО загружаем детали рецептов (партиями по 20)
            var loadedRecipes: [Recipe] = []
            let batchSize = 20
            let totalBatches = (allMeals.count + batchSize - 1) / batchSize
            
            for (batchIndex, batchStart) in stride(from: 0, to: allMeals.count, by: batchSize).enumerated() {
                let batchEnd = min(batchStart + batchSize, allMeals.count)
                let batch = Array(allMeals[batchStart..<batchEnd])
                
                // Загружаем партию параллельно
                let batchMeals = await withTaskGroup(of: (MealDTO, Recipe)?.self) { group in
                    for meal in batch {
                        if !loadedMealIds.contains(meal.idMeal) {
                            loadedMealIds.insert(meal.idMeal)
                            
                            group.addTask {
                                guard let fullMeal = try? await self.mealDBService.getMealDetails(id: meal.idMeal) else {
                                    return nil
                                }
                                // Конвертируем на главном потоке
                                return await MainActor.run {
                                    let recipe = RecipeConverter.convertMealDTOToRecipe(meal: fullMeal, modelContext: self.modelContext)
                                    return (fullMeal, recipe)
                                }
                            }
                        }
                    }
                    
                    var results: [(MealDTO, Recipe)] = []
                    for await result in group {
                        if let result = result {
                            results.append(result)
                        }
                    }
                    return results
                }
                
                // Сохраняем партию в базу (на главном потоке)
                await MainActor.run {
                    for (_, recipe) in batchMeals {
                        modelContext.insert(recipe)
                        loadedRecipes.append(recipe)
                    }
                    
                    // Обновляем прогресс
                    let progress = 0.3 + (0.6 * Double(batchIndex + 1) / Double(totalBatches))
                    loadingProgress = progress
                    loadingStatus = "Loaded \(loadedRecipes.count) of \(allMeals.count) recipes..."
                }
            }
            
            print("✅ Successfully loaded \(loadedRecipes.count) recipes!")
            
            // Шаг 4: Анализируем загруженные рецепты
            await MainActor.run {
                loadingStatus = "Analyzing recipes..."
                loadingProgress = 0.95
            }
            
            await MainActor.run {
                analyzeExistingRecipes()
                loadingProgress = 1.0
                loadingStatus = "Done!"
                isLoading = false
            }
            
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load recipes: \(error.localizedDescription)"
                showError = true
                isLoading = false
            }
        }
    }
    
    /// Анализирует уже загруженные рецепты (мгновенно)
    private func analyzeExistingRecipes() {
        // Убираем дубликаты по названию
        var uniqueRecipes: [Recipe] = []
        var seenTitles: Set<String> = Set()
        
        for recipe in allRecipes {
            if !seenTitles.contains(recipe.title) {
                uniqueRecipes.append(recipe)
                seenTitles.insert(recipe.title)
            }
        }
        
        print("📊 Analyzing \(uniqueRecipes.count) unique recipes against \(inventory.count) products")
        
        // Анализируем совпадения с инвентарем
        recipeMatches = RecipeMatchService.findMatchingRecipes(
            recipes: uniqueRecipes,
            inventory: inventory
        )
        
        print("🎯 Found \(recipeMatches.count) matches")
    }
}

// MARK: - Recipe Row

struct RecommendedRecipeRow: View {
    let match: RecipeMatch
    
    var body: some View {
        HStack(spacing: 12) {
            // Image
            AsyncImage(url: URL(string: match.recipe.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 60, height: 60)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(match.recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // Match percentage
                    HStack(spacing: 4) {
                        Image(systemName: matchIcon)
                            .foregroundStyle(matchColor)
                            .font(.caption)
                        
                        Text("\(Int(match.matchPercentage))% match")
                            .font(.caption)
                            .foregroundStyle(matchColor)
                    }
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text("\(match.matchCount)/\(match.totalCount) ingredients")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if match.missingIngredients.count > 0 && match.missingIngredients.count <= 3 {
                    Text("Missing: \(missingIngredientsList)")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                        .lineLimit(1)
                }
                if match.recipe.isFavorite {
                    Image(systemName: "heart.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            // Match badge
            Circle()
                .fill(matchColor.opacity(0.2))
                .frame(width: 50, height: 50)
                .overlay {
                    Text("\(Int(match.matchPercentage))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(matchColor)
                }
        }
        .padding(.vertical, 4)
    }
    
    private var matchIcon: String {
        if match.matchPercentage >= 70 {
            return "checkmark.circle.fill"
        } else if match.matchPercentage >= 40 {
            return "exclamationmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    private var matchColor: Color {
        if match.matchPercentage >= 70 {
            return .green
        } else if match.matchPercentage >= 40 {
            return .orange
        } else {
            return .red
        }
    }
    
    private var missingIngredientsList: String {
        match.missingIngredients
            .prefix(3)
            .map { $0.ingredientName }
            .joined(separator: ", ")
    }
}

#Preview {
    RecommendedRecipesView()
        .modelContainer(for: [Recipe.self, Product.self], inMemory: true)
}
