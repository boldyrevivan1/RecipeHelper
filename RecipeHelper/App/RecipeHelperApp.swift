//
//  RecipeHelperApp.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

@main
struct RecipeHelperApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            User.self,
            Profile.self,
            Product.self,
            Recipe.self,
            RecipeIngredient.self,
            Ingredient.self,
            ShoppingListItem.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
