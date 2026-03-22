//
//  AddProductView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct AddProductView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var searchText = ""
    @State private var selectedIngredient: String?
    @State private var category = "Other"
    @State private var quantityStatus: ProductQuantityStatus = .medium
    @State private var expirationDate: Date?
    @State private var hasExpirationDate = false
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Поисковые результаты
    private var searchResults: [String] {
        KnownIngredients.search(query: searchText)
    }
    
    // Показывать ли список автодополнения
    private var showSuggestions: Bool {
        !searchText.isEmpty && selectedIngredient == nil
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Product Name with Autocomplete
                Section {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Start typing product name...", text: $searchText)
                            .textInputAutocapitalization(.words)
                            .onChange(of: searchText) { oldValue, newValue in
                                // Сбрасываем выбор при изменении текста
                                if newValue != selectedIngredient {
                                    selectedIngredient = nil
                                }
                            }
                        
                        // Показываем выбранный продукт
                        if let selected = selectedIngredient {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(selected)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button("Change") {
                                    selectedIngredient = nil
                                    searchText = ""
                                }
                                .font(.caption)
                            }
                            .padding(.top, 8)
                        }
                    }
                    
                    // Autocomplete suggestions
                    if showSuggestions {
                        VStack(alignment: .leading, spacing: 0) {
                            if searchResults.isEmpty {
                                Text("No matching ingredients found")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.vertical, 8)
                            } else {
                                ForEach(searchResults.prefix(5), id: \.self) { ingredient in
                                    Button {
                                        selectIngredient(ingredient)
                                    } label: {
                                        HStack {
                                            Image(systemName: "magnifyingglass")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                            Text(ingredient)
                                                .foregroundStyle(.primary)
                                            Spacer()
                                        }
                                        .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .padding(.vertical, 8)
                                    
                                    if ingredient != searchResults.prefix(5).last {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Product Name")
                } footer: {
                    if showSuggestions && !searchResults.isEmpty {
                        Text("Select from \(searchResults.count) matching ingredients")
                            .font(.caption)
                    }
                }
                
                // Category
                Section("Category") {
                    Picker("Category", selection: $category) {
                        Text("Vegetables").tag("Vegetables")
                        Text("Fruits").tag("Fruits")
                        Text("Meat").tag("Meat")
                        Text("Seafood").tag("Seafood")
                        Text("Dairy").tag("Dairy")
                        Text("Grains").tag("Grains")
                        Text("Spices").tag("Spices")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.menu)
                }
                
                // Quantity Status - FIXED VERSION
                Section("Quantity Status") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            StatusButton(
                                title: "Plenty",
                                icon: "checkmark.circle.fill",
                                color: .green,
                                isSelected: quantityStatus == .plenty
                            ) {
                                quantityStatus = .plenty
                            }
                            
                            StatusButton(
                                title: "Medium",
                                icon: "minus.circle.fill",
                                color: .orange,
                                isSelected: quantityStatus == .medium
                            ) {
                                quantityStatus = .medium
                            }
                            
                            StatusButton(
                                title: "Running Out",
                                icon: "exclamationmark.circle.fill",
                                color: .red,
                                isSelected: quantityStatus == .runningOut
                            ) {
                                quantityStatus = .runningOut
                            }
                        }
                    }
                }
                
                // Expiration Date
                Section {
                    Toggle("Has expiration date", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker(
                            "Expiration Date",
                            selection: Binding(
                                get: { expirationDate ?? Date() },
                                set: { expirationDate = $0 }
                            ),
                            displayedComponents: .date
                        )
                    }
                } header: {
                    Text("Expiration")
                }
            }
            .navigationTitle("Add Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProduct()
                    }
                    .disabled(selectedIngredient == nil)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func selectIngredient(_ ingredient: String) {
        selectedIngredient = ingredient
        searchText = ingredient
    }
    
    private func saveProduct() {
        guard let productName = selectedIngredient else {
            errorMessage = "Please select a product from the suggestions"
            showError = true
            return
        }
        
        // Проверяем что ингредиент валидный
        guard KnownIngredients.isValid(ingredient: productName) else {
            errorMessage = "Please select a valid ingredient from the list"
            showError = true
            return
        }
        
        let product = Product(name: productName, quantityStatus: quantityStatus)
        product.expirationDate = hasExpirationDate ? expirationDate : nil
        product.category = category
        
        modelContext.insert(product)
        dismiss()
    }
}

// MARK: - Status Button Component

struct StatusButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(isSelected ? color : .gray.opacity(0.3))
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.15) : Color.gray.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddProductView()
        .modelContainer(for: Product.self, inMemory: true)
}
