//
//  MainTabView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            InventoryView()
                .tabItem {
                    Label("Inventory", systemImage: "refrigerator")
                }
            
            RecommendedRecipesView()
                .tabItem {
                    Label("Recommended", systemImage: "star.fill")
                }
            
           
            RecipesView()
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            
            ShoppingListView()
                .tabItem {
                    Label("Shopping", systemImage: "cart")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
    }
}

#Preview {
    MainTabView()
        .modelContainer(for: [Product.self, Recipe.self, ShoppingListItem.self, User.self], inMemory: true)
}
