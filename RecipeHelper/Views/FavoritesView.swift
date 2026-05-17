import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Recipe> { $0.isFavorite == true }, sort: \Recipe.title)
    private var favoriteRecipes: [Recipe]

    var body: some View {
        NavigationStack {
            Group {
                if favoriteRecipes.isEmpty {
                    emptyStateView
                } else {
                    recipesList
                }
            }
            .navigationTitle("Favorites")
        }
    }

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Favorite Recipes",
            systemImage: "heart.slash",
            description: Text("Tap the heart icon on any recipe to add it to favorites")
        )
    }

    private var recipesList: some View {
        List {
            ForEach(favoriteRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    FavoriteRecipeRow(recipe: recipe)
                }
            }
            .onDelete(perform: removeFromFavorites)
        }
    }

    private func removeFromFavorites(at offsets: IndexSet) {
        for index in offsets {
            favoriteRecipes[index].isFavorite = false
        }
    }
}

struct FavoriteRecipeRow: View {
    let recipe: Recipe

    var body: some View {
        HStack(spacing: 12) {

            AsyncImage(url: URL(string: recipe.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.2)
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.title)
                    .font(.headline)
                    .lineLimit(2)

                HStack(spacing: 12) {
                    Label("\(recipe.preparationTime) min", systemImage: "clock")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let cuisine = recipe.cuisineType {
                    Text(cuisine)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Image(systemName: "heart.fill")
                .foregroundStyle(.red)
                .font(.title3)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: Recipe.self, inMemory: true)
}
