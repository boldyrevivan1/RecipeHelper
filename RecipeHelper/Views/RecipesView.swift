//
//  RecipesView.swift
//  RecipeHelper
//

import SwiftUI
import SwiftData

// MARK: - Filters

enum RecipeFilter: String, CaseIterable {
    case all      = "All"
    case canCook  = "Can Cook"
    case favorite = "Favorites"
}

// MARK: - RecipesView

struct RecipesView: View {
    @Query(sort: \Recipe.title) private var allRecipes: [Recipe]
    @ObservedObject private var fs = FirestoreService.shared

    @State private var searchText        = ""
    @State private var activeFilter:     RecipeFilter = .all
    @State private var selectedCuisine:  String?       = nil

    private let mealDBService = MealDBService.shared

    @State private var isLoading       = false
    @State private var loadingStatus   = ""
    @State private var loadingProgress = 0.0

    // MARK: Computed

    private var matches: [RecipeMatch] {
        RecipeMatchService.findMatchingRecipes(recipes: allRecipes, inventory: fs.products, pantry: fs.pantry)
    }

    private var availableCuisines: [String] {
        let all = allRecipes.compactMap { $0.cuisineType }.filter { !$0.isEmpty }
        return Array(Set(all)).sorted()
    }

    private var userDietary:   [String] { FirestoreService.shared.profile?.dietaryPreferences ?? [] }
    private var userAllergies: [String] { FirestoreService.shared.profile?.allergies ?? [] }

    private var filtered: [RecipeMatch] {
        matches.filter { match in
            let search: Bool
            if searchText.isEmpty {
                search = true
            } else {
                let q = searchText
                // match in title
                let titleHit = match.recipe.title.localizedCaseInsensitiveContains(q)
                // match in any ingredient name
                let ingredientHit = (match.recipe.ingredients ?? []).contains {
                    $0.ingredientName.localizedCaseInsensitiveContains(q)
                }
                // match in cuisine ("italian", "indian", …)
                let cuisineHit = match.recipe.cuisineType?
                    .localizedCaseInsensitiveContains(q) ?? false
                search = titleHit || ingredientHit || cuisineHit
            }

            let filterOK: Bool
            switch activeFilter {
            case .all:      filterOK = true
            case .canCook:  filterOK = match.canCook
            case .favorite: filterOK = match.recipe.isFavorite
            }

            let cuisineOK = selectedCuisine == nil ||
                match.recipe.cuisineType == selectedCuisine

            // Dietary filter
            let tags = match.recipe.dietaryTags ?? []
            let dietaryOK = userDietary.isEmpty ||
                userDietary.allSatisfy { tags.contains($0) }

            // Allergy filter — hide recipes with allergens the user has
            let recipeAllergens = match.recipe.allergens ?? []
            let allergyOK = userAllergies.isEmpty ||
                !userAllergies.contains(where: { recipeAllergens.contains($0) })

            return search && filterOK && cuisineOK && dietaryOK && allergyOK
        }
    }

    private var canCookCount: Int { matches.filter { $0.canCook }.count }

    // MARK: Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                cuisineBar
                contentGroup
            }
            .navigationTitle("Recipes")
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search by name, ingredient, or cuisine"
            )

        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(RecipeFilter.allCases, id: \.self) { filter in
                    FilterChipView(label: chipLabel(for: filter), isActive: activeFilter == filter) {
                        withAnimation { activeFilter = filter }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var cuisineBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChipView(
                    label: selectedCuisine == nil ? "🌍 All cuisines" : "🌍 All",
                    isActive: selectedCuisine == nil,
                    style: .secondary
                ) { withAnimation { selectedCuisine = nil } }

                ForEach(availableCuisines, id: \.self) { cuisine in
                    FilterChipView(
                        label: "\(cuisineFlag(cuisine)) \(cuisine)",
                        isActive: selectedCuisine == cuisine,
                        style: .secondary
                    ) { withAnimation { selectedCuisine = cuisine } }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .bottom) { Divider() }
    }

    private func chipLabel(for filter: RecipeFilter) -> String {
        switch filter {
        case .all:      return "All (\(filtered.count))"
        case .canCook:  return canCookCount > 0 ? "✅ Can Cook (\(canCookCount))" : "Can Cook"
        case .favorite: return "❤️ Favorites"
        }
    }

    private func cuisineFlag(_ cuisine: String) -> String {
        switch cuisine {
        case "Italian":    return "🇮🇹"
        case "American":   return "🇺🇸"
        case "British":    return "🇬🇧"
        case "French":     return "🇫🇷"
        case "Chinese":    return "🇨🇳"
        case "Japanese":   return "🇯🇵"
        case "Indian":     return "🇮🇳"
        case "Mexican":    return "🇲🇽"
        case "Thai":       return "🇹🇭"
        case "Spanish":    return "🇪🇸"
        case "Greek":      return "🇬🇷"
        case "Turkish":    return "🇹🇷"
        case "Moroccan":   return "🇲🇦"
        case "Vietnamese": return "🇻🇳"
        case "Canadian":   return "🇨🇦"
        case "Croatian":   return "🇭🇷"
        case "Dutch":      return "🇳🇱"
        case "Egyptian":   return "🇪🇬"
        case "Filipino":   return "🇵🇭"
        case "Irish":      return "🇮🇪"
        case "Jamaican":   return "🇯🇲"
        case "Kenyan":     return "🇰🇪"
        case "Malaysian":  return "🇲🇾"
        case "Polish":     return "🇵🇱"
        case "Portuguese": return "🇵🇹"
        case "Russian":    return "🇷🇺"
        case "Ukrainian":   return "🇺🇦"
        case "Argentinian": return "🇦🇷"
        case "Peruvian":    return "🇵🇪"
        case "Indonesian":  return "🇮🇩"
        case "Korean":      return "🇰🇷"
        case "Nepali":      return "🇳🇵"
        default:            return "🍽️"
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var contentGroup: some View {
        if allRecipes.isEmpty {
            ContentUnavailableView("No Recipes", systemImage: "book",
                description: Text("Recipes will appear here"))
        } else if filtered.isEmpty {
            ContentUnavailableView("No Results", systemImage: "magnifyingglass",
                description: Text(emptyMessage))
        } else {
            recipeList
        }
    }

    private var emptyMessage: String {
        if let c = selectedCuisine { return "No \(c) recipes match your filters" }
        switch activeFilter {
        case .canCook:  return "Add more products to unlock recipes"
        case .favorite: return "Tap ❤️ on any recipe to favourite it"
        case .all:      return "No recipes matching \"\(searchText)\""
        }
    }

    private var recipeList: some View {
        List {
            ForEach(filtered, id: \.recipe.id) { match in
                NavigationLink(destination: RecipeDetailView(recipe: match.recipe)) {
                    RecipeRowView(match: match)
                }
            }
        }
        .listStyle(.plain)
        .animation(.default, value: filtered.map { $0.recipe.id })
        .safeAreaInset(edge: .bottom) {
            if !CookingSessionManager.shared.sessions.isEmpty {
                Color.clear.frame(height: 70)
            }
        }
    }
}

// MARK: - Recipe Row

struct RecipeRowView: View {
    let match: RecipeMatch

    var body: some View {
        HStack(spacing: 12) {
            CachedAsyncImage(url: match.recipe.imageURL ?? "") { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "fork.knife").foregroundStyle(.gray))
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(match.recipe.title).font(.headline).lineLimit(2)
                    Spacer()
                    if match.recipe.isFavorite {
                        Image(systemName: "heart.fill").foregroundStyle(.red).font(.caption)
                    }
                }
                HStack(spacing: 6) {
                    HStack(spacing: 3) {
                        Image(systemName: "clock").font(.caption2)
                        Text("\(match.recipe.preparationTime) min").font(.caption)
                    }
                    .foregroundStyle(.secondary)

                    Text("·").foregroundStyle(.secondary).font(.caption)

                    Text(match.recipe.difficulty.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let cuisine = match.recipe.cuisineType {
                        Spacer()
                        Text(cuisine)
                            .font(.caption)
                            .lineLimit(1)
                            .padding(.horizontal, 7).padding(.vertical, 2)
                            .background(Color.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                    }
                }

                if match.totalCount > 0 {
                    VStack(alignment: .leading, spacing: 3) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(.systemGray5)).frame(height: 7)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(match.matchPercentage >= 70 ? Color.green : .orange)
                                    .frame(width: geo.size.width * CGFloat(match.matchPercentage / 100), height: 7)
                            }
                        }
                        .frame(height: 5)
                        HStack(spacing: 4) {
                            Text("\(match.matchCount)/\(match.totalCount) ingredients")
                                .font(.caption2)
                                .foregroundStyle(match.matchPercentage >= 70 ? .green : .orange)
                            if match.canCook {
                                Text("· Ready to cook!")
                                    .font(.caption2).fontWeight(.semibold).foregroundStyle(.green)
                            } else if !match.missingIngredients.isEmpty {
                                Text("· Missing: \(match.missingIngredients.prefix(2).joined(separator: ", "))")
                                    .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                            }
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Filter Chip

struct FilterChipView: View {
    enum Style { case primary, secondary }
    let label:    String
    let isActive: Bool
    var style:    Style = .primary
    let action:   () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(style == .primary ? .subheadline : .caption)
                .fontWeight(isActive ? .semibold : .regular)
                .padding(.horizontal, style == .primary ? 14 : 12)
                .padding(.vertical,   style == .primary ? 7  : 5)
                .background(isActive ? Color.blue : Color(.secondarySystemBackground))
                .foregroundStyle(isActive ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecipesView()
        .modelContainer(for: [Recipe.self, RecipeIngredient.self], inMemory: true)
}
