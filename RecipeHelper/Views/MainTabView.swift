//
//  MainTabView.swift
//  RecipeHelper
//

import SwiftUI
import SwiftData

private struct ReopenItem: Identifiable {
    let id:     UUID
    let recipe: Recipe
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @ObservedObject private var cookingManager = CookingSessionManager.shared
    @Query(sort: \Recipe.title) private var recipes: [Recipe]
    @State private var reopenItem: ReopenItem? = nil

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(selectedTab: $selectedTab)
                    .tabItem { Label("Home",      systemImage: "house.fill") }.tag(0)
                InventoryView()
                    .tabItem { Label("Inventory", systemImage: "refrigerator") }.tag(1)
                RecipesView()
                    .tabItem { Label("Recipes",   systemImage: "book") }.tag(2)
                ShoppingListView()
                    .tabItem { Label("Shopping",  systemImage: "cart") }.tag(3)
                ProfileView()
                    .tabItem { Label("Profile",   systemImage: "person") }.tag(4)
            }

            // Mini pill above tab bar
            if !cookingManager.sessions.isEmpty {
                CookingBannerView()
                    .padding(.bottom, 60) // above tab bar
            }
        }
        .onChange(of: cookingManager.selectedSessionId) { _, sessionId in
            guard let sessionId,
                  let session = cookingManager.session(for: sessionId),
                  let recipe  = recipes.first(where: { $0.id == session.recipeId })
            else { return }
            reopenItem = ReopenItem(id: sessionId, recipe: recipe)
            cookingManager.selectedSessionId = nil
        }
        .sheet(item: $reopenItem) { item in
            CookingSessionView(recipe: item.recipe, sessionId: item.id)
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Recipe.self, RecipeIngredient.self], inMemory: true)
}
