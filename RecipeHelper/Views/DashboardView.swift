//
//  DashboardView.swift
//  RecipeHelper
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @ObservedObject private var fs = FirestoreService.shared
    @Query(sort: \Recipe.title) private var recipes: [Recipe]

    @Binding var selectedTab: Int
    @State private var showAddProduct = false
    @State private var showQRScanner  = false
    @State private var surpriseSeed   = 0   // incrementing this shuffles the pick

    private var expiredProducts: [FSProduct] { fs.products.filter { isExpired($0) } }
    private var expiringSoon:    [FSProduct] { fs.products.filter { isExpiringSoon($0) } }

    private var topRecipe: Recipe? {
        let matches = RecipeMatchService.findMatchingRecipes(recipes: recipes, inventory: fs.products, pantry: fs.pantry)
        return matches.first(where: { $0.canCook })?.recipe ?? matches.first?.recipe
    }

    /// Random recipe from those the user CAN actually cook.
    /// Falls back to any recipe if none are cookable.
    /// `surpriseSeed` lets SwiftUI re-evaluate when the user taps "Surprise me".
    private var surpriseRecipe: Recipe? {
        _ = surpriseSeed   // depend on seed so button taps produce a new pick
        let matches = RecipeMatchService.findMatchingRecipes(recipes: recipes, inventory: fs.products, pantry: fs.pantry)
        let cookable = matches.filter { $0.canCook }.map { $0.recipe }
        if let pick = cookable.randomElement() { return pick }
        return recipes.randomElement()
    }

    private func isExpired(_ p: FSProduct) -> Bool {
        guard let d = p.expirationDate else { return false }
        return d < Date()
    }
    private func isExpiringSoon(_ p: FSProduct) -> Bool {
        guard let d = p.expirationDate else { return false }
        let cal = Calendar.current
        let today     = cal.startOfDay(for: Date())
        let expiryDay = cal.startOfDay(for: d)
        let days = cal.dateComponents([.day], from: today, to: expiryDay).day ?? 0
        return days == 1
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    greetingHeader
                    statsRow
                    if !expiredProducts.isEmpty || !expiringSoon.isEmpty {
                        alertsSection
                    }
                    recipeOfTheDay
                    quickActions
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .safeAreaInset(edge: .bottom) {
                if !CookingSessionManager.shared.sessions.isEmpty {
                    Color.clear.frame(height: 70)
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Greeting

    private var greetingHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(greeting).font(.title2).fontWeight(.bold)
                Text("Here's what's in your kitchen")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "house.fill").font(.title).foregroundStyle(.blue)
        }
        .padding(.top, 8)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning 🌅"
        case 12..<17: return "Good afternoon ☀️"
        case 17..<22: return "Good evening 🌆"
        default:      return "Good night 🌙"
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: "\(fs.products.count)", label: "Products",
                     icon: "refrigerator.fill", color: .green)
            StatCard(value: "\(expiringSoon.count)", label: "Expiring Soon",
                     icon: "exclamationmark.triangle.fill", color: .yellow)
            StatCard(value: "\(expiredProducts.count)", label: "Expired",
                     icon: "xmark.circle.fill", color: .red)
        }
    }

    // MARK: - Alerts

    private var alertsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⚠️ Attention Required").font(.headline)
            if !expiredProducts.isEmpty {
                AlertRow(icon: "xmark.circle.fill", color: .red,
                         title: "\(expiredProducts.count) product(s) expired",
                         subtitle: expiredProducts.prefix(3).map { $0.name }.joined(separator: ", "))
            }
            if !expiringSoon.isEmpty {
                AlertRow(icon: "exclamationmark.triangle.fill", color: .orange,
                         title: "\(expiringSoon.count) product(s) expiring soon",
                         subtitle: expiringSoon.prefix(3).map { $0.name }.joined(separator: ", "))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    // MARK: - Recipe of the Day

    /// Which recipe to show — top match by default, random one if user
    /// has tapped "Surprise me" (seed > 0).
    private var featuredRecipe: Recipe? {
        surpriseSeed > 0 ? surpriseRecipe : topRecipe
    }

    private var recipeOfTheDay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(surpriseSeed > 0 ? "🎲 Surprise Recipe" : "🍽️ Recipe of the Day")
                    .font(.headline)
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        surpriseSeed += 1
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "shuffle")
                        Text("Surprise me")
                    }
                    .font(.caption).fontWeight(.semibold)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Color.blue.opacity(0.12))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            if let recipe = featuredRecipe {
                let match = RecipeMatchService.calculateMatch(recipe: recipe, inventory: fs.products, pantry: fs.pantry)
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    recipeCard(recipe: recipe, match: match)
                }
                .buttonStyle(.plain)
                .id(surpriseSeed)   // re-trigger transition on shuffle
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .scale(scale: 0.96)),
                    removal:   .opacity
                ))
            } else {
                ContentUnavailableView("No Recipes Yet", systemImage: "book",
                    description: Text("Open Recipes tab to load recipes"))
                    .frame(height: 120)
            }
        }
    }

    private func recipeCard(recipe: Recipe, match: RecipeMatch) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            CachedAsyncImage(url: recipe.imageURL ?? "") { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray.opacity(0.15)
                    .overlay(Image(systemName: "fork.knife").font(.largeTitle).foregroundStyle(.gray))
            }
            .frame(maxWidth: .infinity).frame(height: 180).clipped()
            .clipShape(UnevenRoundedRectangle(
                topLeadingRadius: 16, bottomLeadingRadius: 0,
                bottomTrailingRadius: 0, topTrailingRadius: 16))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(recipe.title).font(.title3).fontWeight(.bold).foregroundStyle(.primary)
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                }
                HStack(spacing: 12) {
                    Label("\(recipe.preparationTime) min", systemImage: "clock")
                    Label(recipe.difficulty.rawValue, systemImage: "chart.bar")
                    if let cuisine = recipe.cuisineType { Label(cuisine, systemImage: "globe") }
                }
                .font(.caption).foregroundStyle(.secondary)

                if match.totalCount > 0 {
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4).fill(Color(.systemGray5)).frame(height: 6)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(match.matchPercentage >= 70 ? Color.green : .orange)
                                    .frame(width: geo.size.width * CGFloat(match.matchPercentage / 100), height: 6)
                            }
                        }.frame(height: 6)
                        Text("\(match.matchCount)/\(match.totalCount) ingredients")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if match.canCook {
                        Label("Ready to cook!", systemImage: "checkmark.circle.fill")
                            .font(.caption).fontWeight(.semibold).foregroundStyle(.green)
                    } else if !match.missingIngredients.isEmpty {
                        Text("Missing: \(match.missingIngredients.prefix(3).joined(separator: ", "))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(14)
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16).clipped()
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions").font(.headline)
            HStack(spacing: 12) {
                QuickActionButton(label: "Add Product", icon: "plus.circle.fill", color: .blue) {
                    showAddProduct = true
                }
                QuickActionButton(label: "Scan Receipt", icon: "doc.text.viewfinder", color: .purple) {
                    showQRScanner = true
                }
                QuickActionButton(label: "Shopping List", icon: "cart.fill", color: .green) {
                    selectedTab = 3
                }
            }
        }
        .sheet(isPresented: $showAddProduct) { AddProductView() }
        .sheet(isPresented: $showQRScanner)  { QRScannerView() }
    }
}

// MARK: - Stat Card

private struct StatCard: View {
    let value: String; let label: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.title2).fontWeight(.bold)
            Text(label).font(.caption2).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 16)
        .background(Color(.secondarySystemBackground)).cornerRadius(14)
    }
}

// MARK: - Alert Row

private struct AlertRow: View {
    let icon: String; let color: Color; let title: String; let subtitle: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(color).font(.title3)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).fontWeight(.medium)
                Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let label: String; let icon: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title2).foregroundStyle(.white)
                    .frame(width: 48, height: 48).background(color).cornerRadius(12)
                Text(label).font(.caption2).multilineTextAlignment(.center).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DashboardView(selectedTab: .constant(0))
        .modelContainer(for: Recipe.self, inMemory: true)
}
