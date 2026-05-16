//
//  CookingSessionView.swift
//  RecipeHelper
//

import SwiftUI
import SwiftData

struct CookingSessionView: View {
    let recipe:    Recipe
    let sessionId: UUID

    @Environment(\.dismiss)      private var dismiss
    @ObservedObject private var manager = CookingSessionManager.shared
    @ObservedObject private var fs      = FirestoreService.shared

    @State private var rows:  [CookingIngredientRow] = []
    @State private var phase: Phase = .timer

    enum Phase { case timer, review }

    private var session: ActiveCookingSession? { manager.session(for: sessionId) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if phase == .timer { timerPhase } else { reviewPhase }
            }
            .navigationTitle(recipe.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Minimize") { dismiss() }
                }
            }
            .onAppear { if rows.isEmpty { buildRows() } }
        }
    }

    // MARK: - Timer Phase

    private var timerPhase: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle().stroke(Color(.systemGray5), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: session?.progress ?? 0)
                    .stroke(
                        (session?.isRunning == true) ? Color.orange : Color.blue,
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: session?.progress)
                VStack(spacing: 6) {
                    Text(session?.timeString ?? "--:--")
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                    Text("remaining").font(.subheadline).foregroundStyle(.secondary)
                }
            }
            .frame(width: 220, height: 220)

            HStack(spacing: 20) {
                Label("\(recipe.preparationTime) min", systemImage: "clock")
                if let cuisine = recipe.cuisineType { Label(cuisine, systemImage: "globe") }
            }
            .font(.subheadline).foregroundStyle(.secondary)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    session?.isRunning == true
                        ? manager.pauseTimer(for: sessionId)
                        : manager.startTimer(for: sessionId)
                } label: {
                    Label(
                        session?.isRunning == true ? "Pause" :
                            ((session?.remainingSeconds ?? 0) < (session?.totalSeconds ?? 0) ? "Resume" : "Start Cooking"),
                        systemImage: session?.isRunning == true ? "pause.fill" : "play.fill"
                    )
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(session?.isRunning == true ? Color.orange : Color.green)
                    .foregroundStyle(.white).clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    manager.pauseTimer(for: sessionId)
                    withAnimation { phase = .review }
                } label: {
                    Label("Finish Cooking", systemImage: "checkmark.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding()
                        .background(Color(.secondarySystemBackground))
                        .foregroundStyle(.primary).clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .onChange(of: session?.isFinished) { _, finished in
            if finished == true { withAnimation { phase = .review } }
        }
    }

    // MARK: - Review Phase

    private var reviewPhase: some View {
        VStack(spacing: 0) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Label("Great job! 🎉", systemImage: "star.fill")
                            .font(.headline).foregroundStyle(.orange)
                        Text("Update how much of each ingredient you used.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                Section("Ingredients in your inventory") {
                    if rows.isEmpty {
                        Text("None of the required ingredients found in inventory.")
                            .foregroundStyle(.secondary).font(.subheadline)
                    } else {
                        ForEach($rows) { $row in FSCookingRowView(row: $row) }
                    }
                }
            }
            Button { applyChanges() } label: {
                Text("Save & Done")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24).padding(.vertical, 16)
        }
    }

    // MARK: - Build Rows

    private func buildRows() {
        guard let ingredients = recipe.ingredients else { return }
        let pantry = fs.pantry
        rows = ingredients.compactMap { ing in
            if RecipeMatchService.isIgnored(ing.ingredientName) { return nil }
            if RecipeMatchService.isInPantry(ing.ingredientName, pantry: pantry) { return nil }
            guard let product = findProduct(for: ing.ingredientName) else { return nil }
            var row = CookingIngredientRow(product: product, action: .skip)
            switch product.quantityStatus {
            case "Plenty": row.action = .toMedium
            default:       row.action = .remove
            }
            return row
        }
    }

    private func findProduct(for name: String) -> FSProduct? {
        let lower = name.lowercased()
        return fs.products.first {
            let n = $0.name.lowercased()
            return n == lower || n.contains(lower) || lower.contains(n)
        }
    }

    // MARK: - Apply

    private func applyChanges() {
        Task {
            for row in rows {
                guard let id = row.product.id else { continue }
                switch row.action {
                case .skip: break
                case .toMedium:
                    var updated = row.product
                    updated.quantityStatus = "Medium"
                    try? await FirestoreService.shared.updateProduct(updated)
                case .remove:
                    try? await FirestoreService.shared.deleteProduct(id: id)
                }
            }
            try? await FirestoreService.shared.addHistory(
                recipeTitle: recipe.title,
                imageURL:    recipe.imageURL,
                cuisine:     recipe.cuisineType
            )
        }
        manager.removeSession(sessionId)
        dismiss()
    }
}

// MARK: - Row Model

struct CookingIngredientRow: Identifiable {
    let id = UUID()
    let product: FSProduct
    var action: CookAction
    enum CookAction { case skip, toMedium, remove }
}

// MARK: - Row View

private struct FSCookingRowView: View {
    @Binding var row: CookingIngredientRow

    private var statusColor: Color {
        row.product.quantityStatus == "Plenty" ? .green : .orange
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: row.product.quantityStatus == "Plenty" ? "checkmark.circle.fill" : "minus.circle.fill")
                    .foregroundStyle(statusColor)
                Text(row.product.name).font(.headline)
                Spacer()
                Text(row.product.quantityStatus).font(.caption).foregroundStyle(statusColor)
            }
            HStack(spacing: 8) {
                FSActionChip(label: "Keep", icon: "checkmark", color: .green,
                             isSelected: row.action == .skip) { row.action = .skip }
                if row.product.quantityStatus == "Plenty" {
                    FSActionChip(label: "Used some", icon: "minus.circle", color: .orange,
                                 isSelected: row.action == .toMedium) { row.action = .toMedium }
                }
                FSActionChip(label: "Used up", icon: "trash", color: .red,
                             isSelected: row.action == .remove) { row.action = .remove }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct FSActionChip: View {
    let label: String; let icon: String; let color: Color
    let isSelected: Bool; let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon).font(.caption2)
                Text(label).font(.caption)
            }
            .padding(.horizontal, 10).padding(.vertical, 6)
            .background(isSelected ? color.opacity(0.15) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? color : .secondary)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? color : Color.clear, lineWidth: 1.5))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }
}
