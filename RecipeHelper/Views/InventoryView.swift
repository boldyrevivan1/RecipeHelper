import SwiftUI

enum InventoryFilter: String, CaseIterable {
    case all     = "All"
    case expired = "Expired"
}

private let categoryOrder: [String] = [
    "Meat", "Seafood", "Dairy", "Vegetables", "Fruits",
    "Bakery", "Grains", "Oils", "Sauces", "Spices",
    "Baking", "Nuts", "Legumes", "Other"
]

private let categoryIcon: [String: String] = [
    "Meat": "fork.knife", "Seafood": "water.waves", "Dairy": "cup.and.saucer.fill",
    "Vegetables": "leaf.fill", "Fruits": "apple.logo", "Bakery": "birthday.cake.fill",
    "Grains": "oval.fill", "Oils": "drop.fill", "Sauces": "mug.fill",
    "Spices": "sparkles", "Baking": "birthday.cake", "Nuts": "circle.hexagonpath.fill",
    "Legumes": "circle.grid.3x3.fill", "Other": "archivebox.fill",
]

private let categoryColor: [String: String] = [
    "Meat": "FF6B6B", "Seafood": "4ECDC4", "Dairy": "A8D8EA",
    "Vegetables": "56C785", "Fruits": "FF9F43", "Bakery": "D4A574",
    "Grains": "F7DC6F", "Oils": "F8C471", "Sauces": "E74C3C",
    "Spices": "AF7AC5", "Baking": "F1948A", "Nuts": "A9754E",
    "Legumes": "82C785", "Other": "95A5A6",
]

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8)  & 0xFF) / 255
        let b = Double(int & 0xFF)         / 255
        self.init(red: r, green: g, blue: b)
    }
}

struct InventoryView: View {
    @ObservedObject private var fs = FirestoreService.shared

    @State private var showAddProduct  = false
    @State private var showQRScanner   = false
    @State private var showPantry      = false
    @State private var searchText      = ""
    @State private var activeFilter:   InventoryFilter = .all
    @State private var editingProduct: FSProduct?

    private var filtered: [FSProduct] {
        fs.products.filter { product in
            let matchesSearch = searchText.isEmpty ||
                product.name.localizedCaseInsensitiveContains(searchText)
            let matchesFilter: Bool
            switch activeFilter {
            case .all:     matchesFilter = true
            case .expired: matchesFilter = isExpired(product)
            }
            return matchesSearch && matchesFilter
        }
    }

    private var grouped: [(category: String, products: [FSProduct])] {
        let dict = Dictionary(grouping: filtered) { $0.category ?? "Other" }
        let ordered = categoryOrder.compactMap { cat -> (String, [FSProduct])? in
            guard let items = dict[cat], !items.isEmpty else { return nil }
            return (cat, items)
        }
        let known = Set(categoryOrder)
        let extra = dict.filter { !known.contains($0.key) && !$0.value.isEmpty }
            .sorted { $0.key < $1.key }
        return (ordered + extra).map { (category: $0.0, products: $0.1) }
    }

    private var expiredCount: Int { fs.products.filter { isExpired($0) }.count }

    private func isExpired(_ p: FSProduct) -> Bool {
        guard let date = p.expirationDate else { return false }
        return date < Date()
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                contentGroup
            }
            .navigationTitle("Inventory")
            .searchable(text: $searchText, prompt: "Search products...")
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddProduct) { AddProductView() }
            .sheet(isPresented: $showQRScanner)  { QRScannerView() }
            .sheet(isPresented: $showPantry)     { PantryView() }
            .sheet(item: $editingProduct) { product in
                EditProductView(product: product)
            }
        }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(InventoryFilter.allCases, id: \.self) { filter in
                    FilterChipView(label: chipLabel(for: filter), isActive: activeFilter == filter) {
                        withAnimation(.easeInOut(duration: 0.2)) { activeFilter = filter }
                    }
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 10)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func chipLabel(for filter: InventoryFilter) -> String {
        switch filter {
        case .all:     return "All (\(fs.products.count))"
        case .expired: return expiredCount > 0 ? "🔴 Expired (\(expiredCount))" : "Expired"
        }
    }

    @ViewBuilder
    private var contentGroup: some View {
        if fs.products.isEmpty {
            ContentUnavailableView("No Products", systemImage: "refrigerator",
                description: Text("Add products to start tracking your inventory"))
        } else if filtered.isEmpty {
            ContentUnavailableView("No Results", systemImage: "magnifyingglass",
                description: Text("No products matching \"\(searchText)\""))
        } else {
            productsList
        }
    }

    private var productsList: some View {
        List {
            if activeFilter == .expired && !filtered.isEmpty {
                Section {
                    Button {
                        Task {
                            for product in filtered {
                                if let id = product.id {
                                    let item = FSShoppingItem(
                                        ingredientName: product.name,
                                        quantity: 1, unit: "pcs",
                                        isPurchased: false, addedDate: Date()
                                    )
                                    try? await FirestoreService.shared.addShoppingItem(item)
                                    try? await FirestoreService.shared.deleteProduct(id: id)
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "cart.badge.plus").font(.title3).foregroundStyle(.white)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Move all to Shopping List")
                                    .font(.subheadline).fontWeight(.semibold).foregroundStyle(.white)
                                Text("\(filtered.count) expired item(s) will be removed")
                                    .font(.caption).foregroundStyle(.white.opacity(0.85))
                            }
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.red.opacity(0.85))
                }
            }

            ForEach(grouped, id: \.category) { group in
                Section {
                    ForEach(group.products) { product in
                        FSProductRow(product: product, isExpired: isExpired(product))
                            .contentShape(Rectangle())
                            .onTapGesture { editingProduct = product }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    Task { if let id = product.id { try? await fs.deleteProduct(id: id) } }
                                } label: { Label("Delete", systemImage: "trash") }

                                Button {
                                    editingProduct = product
                                } label: { Label("Edit", systemImage: "pencil") }
                                .tint(.blue)
                            }
                            .swipeActions(edge: .leading) {
                                if isExpired(product) {
                                    Button {
                                        Task {
                                            if let id = product.id {
                                                let item = FSShoppingItem(
                                                    ingredientName: product.name,
                                                    quantity: 1, unit: "pcs",
                                                    isPurchased: false, addedDate: Date()
                                                )
                                                try? await fs.addShoppingItem(item)
                                                try? await fs.deleteProduct(id: id)
                                            }
                                        }
                                    } label: { Label("Restock", systemImage: "cart.badge.plus") }
                                    .tint(.orange)
                                }
                            }
                    }
                } header: {
                    FSCategoryHeader(title: group.category,
                                   icon: categoryIcon[group.category] ?? "archivebox.fill",
                                   count: group.products.count)
                }
            }
        }
        .listStyle(.insetGrouped)
        .animation(.default, value: filtered.map { $0.id })
        .safeAreaInset(edge: .bottom) {
            if !CookingSessionManager.shared.sessions.isEmpty {
                Color.clear.frame(height: 70)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .navigationBarTrailing) {
            Button { showPantry = true } label: {
                Image(systemName: "leaf.fill")
            }
            Menu {
                Button { showAddProduct = true } label: { Label("Add Manually", systemImage: "plus.circle") }
                Button { showQRScanner = true }  label: { Label("Scan Receipt", systemImage: "doc.text.viewfinder") }
            } label: { Image(systemName: "plus").font(.title3) }
        }
    }
}

struct FSProductRow: View {
    let product:   FSProduct
    let isExpired: Bool

    private var statusIcon:  String { QuantityStatusStyle.icon(for: product.quantityStatus) }
    private var statusColor: Color  { QuantityStatusStyle.color(for: product.quantityStatus) }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: statusIcon).font(.title2).foregroundStyle(statusColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name).font(.headline)
                if let expDate = product.expirationDate {
                    HStack(spacing: 4) {
                        Image(systemName: isExpired ? "exclamationmark.triangle.fill" : "calendar").font(.caption)
                        Text(expiryLabel(expDate)).font(.caption)
                    }
                    .foregroundStyle(isExpired ? .red : .secondary)
                }
            }
            Spacer()
            Text(product.quantityStatus)
                .font(.caption2)
                .padding(.horizontal, 8).padding(.vertical, 3)
                .background(statusColor.opacity(0.15))
                .foregroundStyle(statusColor)
                .clipShape(Capsule())
        }
        .padding(.vertical, 2)
    }

    private func expiryLabel(_ date: Date) -> String {
        if isExpired { return "Expired" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        if days == 0 { return "Expires today" }
        if days == 1 { return "Expires tomorrow" }
        if days <= 7 { return "Expires in \(days) days" }
        return "Exp: \(date.formatted(date: .abbreviated, time: .omitted))"
    }
}

private struct FSCategoryHeader: View {
    let title: String; let icon: String; let count: Int
    private var color: Color { Color(hex: categoryColor[title] ?? "4A90D9") }
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.caption).foregroundStyle(color)
            Text(title).font(.caption).fontWeight(.semibold).foregroundStyle(.primary)
            Spacer()
            Text("\(count)").font(.caption2).foregroundStyle(.white)
                .padding(.horizontal, 6).padding(.vertical, 2)
                .background(color).clipShape(Capsule())
        }
    }
}

#Preview { InventoryView() }
