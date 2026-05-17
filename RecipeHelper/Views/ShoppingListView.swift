import SwiftUI

struct ShoppingListView: View {
    @ObservedObject private var fs = FirestoreService.shared
    @State private var showShareSheet = false
    @State private var showMoveSheet  = false

    private var grouped: [String: [FSShoppingItem]] {
        Dictionary(grouping: fs.shoppingList) { item in
            determineCategory(for: item.ingredientName)
        }
    }

    private var sortedCategories: [String] {
        let order = ["Meat","Seafood","Dairy","Vegetables","Fruits",
                     "Bakery","Grains","Oils","Sauces","Spices",
                     "Baking","Nuts","Legumes","Other"]
        return grouped.keys.sorted {
            let i1 = order.firstIndex(of: $0) ?? order.count
            let i2 = order.firstIndex(of: $1) ?? order.count
            return i1 < i2
        }
    }

    private var purchasedCount: Int { fs.shoppingList.filter { $0.isPurchased }.count }
    private var remainingCount: Int { fs.shoppingList.count - purchasedCount }

    var body: some View {
        NavigationStack {
            Group {
                if fs.shoppingList.isEmpty {
                    ContentUnavailableView("No Items", systemImage: "cart",
                        description: Text("Add missing ingredients from recipes to create your shopping list"))
                } else {
                    shoppingList
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button { showShareSheet = true } label: {
                            Label("Share List", systemImage: "square.and.arrow.up")
                        }
                        if !fs.shoppingList.isEmpty {
                            Divider()
                            Button(role: .destructive) {
                                Task { try? await fs.clearPurchasedItems() }
                            } label: { Label("Clear Purchased", systemImage: "trash") }
                        }
                    } label: { Image(systemName: "ellipsis.circle") }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [generateText()])
            }
            .sheet(isPresented: $showMoveSheet) {
                MoveToInventorySheet(
                    items: fs.shoppingList.filter { $0.isPurchased }
                )
            }
        }
    }

    private var shoppingList: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(fs.shoppingList.count) items total").font(.headline)
                        Text("\(purchasedCount) purchased • \(remainingCount) remaining")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showShareSheet = true } label: {
                        Image(systemName: "square.and.arrow.up").font(.title3).foregroundStyle(.blue)
                    }
                }
                .padding(.vertical, 4)
            }

            ForEach(sortedCategories, id: \.self) { category in
                let items = grouped[category] ?? []
                if !items.isEmpty {
                    Section {
                        ForEach(items) { item in
                            FSShoppingItemRow(item: item)
                        }
                        .onDelete { offsets in
                            Task {
                                for i in offsets {
                                    if let id = items[i].id {
                                        try? await fs.deleteShoppingItem(id: id)
                                    }
                                }
                            }
                        }
                    } header: {
                        HStack(spacing: 6) {
                            Text(categoryIcon(for: category))
                            Text(category).font(.caption).fontWeight(.semibold)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 0) {
                if purchasedCount > 0 { moveToInventoryButton }
                if !CookingSessionManager.shared.sessions.isEmpty { Color.clear.frame(height: 70) }
            }
        }
    }

    private var moveToInventoryButton: some View {
        Button {
            showMoveSheet = true
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack {
                Image(systemName: "tray.and.arrow.down.fill")
                Text("Move \(purchasedCount) to Inventory")
                    .fontWeight(.semibold)
            }
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.green)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .shadow(color: .green.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: purchasedCount)
    }

    private func determineCategory(for ingredient: String) -> String {
        if let match = IngredientMatcher.entries.values.first(where: {
            $0.englishName.lowercased() == ingredient.lowercased()
        }) { return match.category }
        if let match = IngredientMatcher.entries.values.first(where: {
            ingredient.lowercased().contains($0.englishName.lowercased()) ||
            $0.englishName.lowercased().contains(ingredient.lowercased())
        }) { return match.category }
        return "Other"
    }

    private func categoryIcon(for category: String) -> String {
        switch category {
        case "Meat": return "🥩"; case "Seafood": return "🐟"; case "Dairy": return "🥛"
        case "Vegetables": return "🥬"; case "Fruits": return "🍎"; case "Bakery": return "🍞"
        case "Grains": return "🌾"; case "Oils": return "🫙"; case "Sauces": return "🥫"
        case "Spices": return "🧂"; case "Baking": return "🧁"; case "Nuts": return "🥜"
        case "Legumes": return "🫘"; default: return "📦"
        }
    }

    private func generateText() -> String {
        var text = "🛒 Shopping List\n\n"
        for cat in sortedCategories {
            let items = grouped[cat] ?? []
            if !items.isEmpty {
                text += "\(categoryIcon(for: cat)) \(cat):\n"
                for item in items {
                    let check = item.isPurchased ? "✓" : "☐"
                    text += "\(check) \(item.ingredientName)"
                    if !item.unit.isEmpty && item.unit != "pcs" { text += " — \(item.unit)" }
                    text += "\n"
                }
                text += "\n"
            }
        }
        return text
    }
}

struct FSShoppingItemRow: View {
    let item: FSShoppingItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                Task {
                    if let id = item.id {
                        try? await FirestoreService.shared.toggleShoppingItem(
                            id: id, isPurchased: !item.isPurchased
                        )
                    }
                }
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(item.isPurchased ? .green : .gray)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.ingredientName)
                    .font(.body)
                    .strikethrough(item.isPurchased)
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)

                HStack(spacing: 8) {
                    if !item.unit.isEmpty && item.unit != "pcs" && item.unit != "pc" {
                        Text(item.unit).font(.caption).foregroundStyle(.secondary)
                    }
                    if let recipe = item.recipeName {
                        Text("•").foregroundStyle(.secondary)
                        Text(recipe).font(.caption).foregroundStyle(.blue)
                    }
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

struct MoveToInventorySheet: View {
    let items: [FSShoppingItem]

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fs = FirestoreService.shared

    @State private var qty: [String: String] = [:]
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle").foregroundStyle(.secondary)
                        Text("Tap a row to change amount. Items already in your inventory will be refreshed with the new date.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                } header: {
                    Text("\(items.count) item\(items.count == 1 ? "" : "s") to add")
                        .textCase(nil)
                }

                Section {
                    ForEach(items) { item in
                        itemRow(item)
                    }
                }
            }
            .navigationTitle("Add to Inventory")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await performMove() }
                    } label: {
                        if isSaving { ProgressView() }
                        else       { Text("Move").fontWeight(.semibold) }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {

                for item in items {
                    if let id = item.id, qty[id] == nil { qty[id] = "Plenty" }
                }
            }
        }
    }

    @ViewBuilder
    private func itemRow(_ item: FSShoppingItem) -> some View {
        let id = item.id ?? ""
        let current = qty[id] ?? "Plenty"
        let existing = existingProduct(for: item.ingredientName)

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.ingredientName).font(.body)
                    if existing != nil {
                        Text("Already in inventory — will refresh")
                            .font(.caption2).foregroundStyle(.orange)
                    } else if let recipe = item.recipeName {
                        Text(recipe).font(.caption2).foregroundStyle(.blue)
                    }
                }
                Spacer()
            }

            HStack(spacing: 10) {
                ForEach(["Plenty", "Medium"], id: \.self) { status in
                    let statusColor = QuantityStatusStyle.color(for: status)
                    let statusIcon  = QuantityStatusStyle.icon(for: status)
                    let isSelected  = current == status
                    Button {
                        qty[id] = status
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: statusIcon).font(.subheadline)
                                .foregroundStyle(isSelected ? statusColor : .gray.opacity(0.4))
                            Text(status).font(.caption).fontWeight(.medium)
                                .foregroundStyle(isSelected ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8)
                            .fill(isSelected ? statusColor.opacity(0.15) : Color.gray.opacity(0.05)))
                        .overlay(RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? statusColor : Color.clear, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func existingProduct(for name: String) -> FSProduct? {
        let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
        return fs.products.first { $0.name.lowercased() == lower }
    }

    private func performMove() async {
        isSaving = true
        defer { isSaving = false }

        for item in items {
            let chosenStatus = qty[item.id ?? ""] ?? "Plenty"
            let match        = IngredientMatcher.match(englishName: item.ingredientName)
            let expiration: Date? = match.flatMap {
                Calendar.current.date(byAdding: .day, value: $0.defaultDays, to: Date())
            }

            if let existing = existingProduct(for: item.ingredientName),
               let existingId = existing.id {

                var updated = existing
                updated.quantityStatus = chosenStatus
                updated.expirationDate = expiration ?? existing.expirationDate
                updated.addedDate      = Date()
                try? await fs.updateProduct(updated)
            } else {

                let product = FSProduct(
                    name:           item.ingredientName,
                    quantityStatus: chosenStatus,
                    expirationDate: expiration,
                    addedDate:      Date(),
                    category:       match?.category ?? "Other"
                )
                try? await fs.addProduct(product)
            }

            if let id = item.id {
                try? await fs.deleteShoppingItem(id: id)
            }
        }

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        dismiss()
    }
}
