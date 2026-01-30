//
//  RecipeDetailView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Image
                AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    Text(recipe.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Information
                    HStack(spacing: 20) {
                        Label("\(recipe.preparationTime) min", systemImage: "clock")
                        Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        Label("\(recipe.servings) servings", systemImage: "person.2")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
                    if let cuisine = recipe.cuisineType {
                        Text(cuisine)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    // Ingredients
                    Text("Ingredients")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if let ingredients = recipe.ingredients {
                        ForEach(ingredients) { ingredient in
                            HStack {
                                Text("•")
                                Text(ingredient.ingredientName)
                                Spacer()
                                Text("\(ingredient.unit)")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Instructions
                    Text("Instructions")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1).")
                                .fontWeight(.semibold)
                                .foregroundStyle(.blue)
                            
                            Text(step)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
