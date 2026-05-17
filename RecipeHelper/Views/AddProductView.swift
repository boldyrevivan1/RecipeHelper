import SwiftUI

struct AddProductView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var searchText          = ""
    @State private var selectedIngredient: String?
    @State private var category            = "Other"
    @State private var quantityStatus      = "Plenty"
    @State private var hasExpirationDate   = false
    @State private var expirationDate      = Date()
    @State private var showPantryAlert     = false

    @ObservedObject private var fs = FirestoreService.shared

    private let allCategories = [
        "Meat","Seafood","Dairy","Vegetables","Fruits",
        "Bakery","Grains","Oils","Sauces","Spices",
        "Baking","Nuts","Legumes","Other"
    ]

    private var searchResults: [String] { KnownIngredients.search(query: searchText) }
    private var showSuggestions: Bool { !searchText.isEmpty && selectedIngredient == nil && !searchResults.isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Start typing product name...", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .onChange(of: searchText) { _, new in
                            if new != selectedIngredient { selectedIngredient = nil }
                        }
                    if let selected = selectedIngredient {
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                            Text(selected).foregroundStyle(.secondary)
                            Spacer()
                            Button("Change") { selectedIngredient = nil; searchText = ""; category = "Other"; hasExpirationDate = false }
                                .font(.caption)
                        }
                        if isInPantry(selected) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "leaf.fill").foregroundStyle(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Already in your Pantry")
                                        .font(.caption).fontWeight(.semibold)
                                    Text("This spice is already marked as always available. You don't need to track it in the inventory.")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        } else if isInInventory(selected) {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .foregroundStyle(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Already in your Inventory")
                                        .font(.caption).fontWeight(.semibold)
                                    Text("Saving will refresh the existing entry — quantity and expiration will be updated, no duplicate will be created.")
                                        .font(.caption2).foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    if showSuggestions {
                        ForEach(searchResults.prefix(5), id: \.self) { ingredient in
                            Button { selectIngredient(ingredient) } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass").font(.caption).foregroundStyle(.secondary)
                                    Text(ingredient).foregroundStyle(.primary)
                                    Spacer()
                                    if let m = matchByEnglish(ingredient) {
                                        Text(m.category).font(.caption2).foregroundStyle(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain).padding(.vertical, 6)
                        }
                    }
                } header: { Text("Product Name") }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(allCategories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                Section("Quantity Status") {
                    HStack(spacing: 12) {
                        ForEach(["Plenty", "Medium"], id: \.self) { status in
                            let statusColor = QuantityStatusStyle.color(for: status)
                            let statusIcon  = QuantityStatusStyle.icon(for: status)
                            Button { quantityStatus = status } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: statusIcon).font(.title2)
                                        .foregroundStyle(quantityStatus == status ? statusColor : .gray.opacity(0.4))
                                    Text(status).font(.caption)
                                        .foregroundStyle(quantityStatus == status ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(quantityStatus == status ? statusColor.opacity(0.15) : Color.gray.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(quantityStatus == status ? statusColor : Color.clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Toggle("Has expiration date", isOn: $hasExpirationDate)
                    if hasExpirationDate {
                        DatePicker("Expiration Date", selection: $expirationDate, in: Date()..., displayedComponents: .date)
                    }
                } header: { Text("Expiration") }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let name = selectedIngredient, isInPantry(name) {
                            showPantryAlert = true
                        } else {
                            saveProduct()
                        }
                    }
                    .disabled(selectedIngredient == nil)
                    .fontWeight(.semibold)
                }
            }
            .alert("Already in Pantry", isPresented: $showPantryAlert) {
                Button("Add anyway") { saveProduct() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\"\(selectedIngredient ?? "")\" is already in your Pantry. Recipes will treat it as always available. Are you sure you want to also track it in the inventory?")
            }
        }
    }

    private func isInPantry(_ name: String) -> Bool {
        RecipeMatchService.isInPantry(name, pantry: fs.pantry)
    }

    private func isInInventory(_ name: String) -> Bool {
        let target = name.lowercased().trimmingCharacters(in: .whitespaces)
        return fs.products.contains {
            $0.name.lowercased().trimmingCharacters(in: .whitespaces) == target
        }
    }

    private func selectIngredient(_ ingredient: String) {
        selectedIngredient = ingredient
        searchText = ingredient
        if let match = matchByEnglish(ingredient) {
            category = match.category
            hasExpirationDate = true
            expirationDate = Calendar.current.date(byAdding: .day, value: match.defaultDays, to: Date()) ?? Date()
        }
    }

    private func matchByEnglish(_ name: String) -> IngredientMatch? {
        IngredientMatcher.entries.values.first { $0.englishName.lowercased() == name.lowercased() }
    }

    private func saveProduct() {
        guard let name = selectedIngredient else { return }

        let existing = fs.products.first {
            $0.name.lowercased().trimmingCharacters(in: .whitespaces)
                == name.lowercased().trimmingCharacters(in: .whitespaces)
        }

        Task {
            if var existing, let id = existing.id {
                existing.quantityStatus = quantityStatus
                existing.expirationDate = hasExpirationDate ? expirationDate : existing.expirationDate
                existing.addedDate      = Date()
                existing.category       = category
                _ = id
                try? await FirestoreService.shared.updateProduct(existing)
            } else {
                let product = FSProduct(
                    name: name,
                    quantityStatus: quantityStatus,
                    expirationDate: hasExpirationDate ? expirationDate : nil,
                    addedDate: Date(),
                    category: category
                )
                try? await FirestoreService.shared.addProduct(product)
            }
        }
        dismiss()
    }
}

#Preview { AddProductView() }
