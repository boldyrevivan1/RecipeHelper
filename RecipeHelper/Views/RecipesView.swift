//
//  RecipesView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct RecipesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var recipes: [Recipe]
    
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading recipes...")
                } else if recipes.isEmpty {
                    ContentUnavailableView {
                        Label("No Recipes", systemImage: "book.closed")
                    } description: {
                        Text("Try searching for recipes or load a random one")
                    } actions: {
                        Button("Random Recipe") {
                            Task {
                                await loadRandomRecipe()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(recipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeRowView(recipe: recipe)
                            }
                        }
                        .onDelete(perform: deleteRecipes)
                    }
                }
            }
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
            .onSubmit(of: .search) {
                Task {
                    await searchRecipes()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            Task {
                                await loadRandomRecipe()
                            }
                        } label: {
                            Label("Random Recipe", systemImage: "shuffle")
                        }
                        
                        Button(role: .destructive) {
                            deleteAllRecipes()
                        } label: {
                            Label("Delete All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "Unknown error")
            }
        }
    }
    
    private func searchRecipes() async {
        guard !searchText.isEmpty else { return }
        
        isLoading = true
        
        do {
            let meals = try await MealDBService.shared.searchMeals(query: searchText)
            
            await MainActor.run {
                for meal in meals {
                    let recipe = RecipeConverter.convertMealDTOToRecipe(meal: meal, modelContext: modelContext)
                    modelContext.insert(recipe)
                }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
    
    private func loadRandomRecipe() async {
        isLoading = true
        
        do {
            if let meal = try await MealDBService.shared.getRandomMeal() {
                await MainActor.run {
                    let recipe = RecipeConverter.convertMealDTOToRecipe(meal: meal, modelContext: modelContext)
                    modelContext.insert(recipe)
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
    
    private func deleteRecipes(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(recipes[index])
            }
        }
    }
    
    private func deleteAllRecipes() {
        withAnimation {
            for recipe in recipes {
                modelContext.delete(recipe)
            }
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe image
            AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack {
                    Label("\(recipe.preparationTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("•")
                        .foregroundStyle(.secondary)
                    
                    Text(recipe.difficulty.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                if let cuisine = recipe.cuisineType {
                    Text(cuisine)
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    RecipesView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
