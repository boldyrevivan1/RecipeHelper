//
//  ReceiptProductsSelectionView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 15.03.2026.
//

import SwiftUI
import SwiftData

struct ReceiptProductsSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    let matchedProducts: [MatchedProduct]
    
    @State private var selectedProducts: Set<String> = []
    @State private var showSuccessAlert = false
    @State private var addedCount = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Products from Receipt")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Select food products to add to inventory")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(matchedProducts.count) food products found")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text("\(selectedProducts.count) selected")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Products list
                List {
                    ForEach(matchedProducts, id: \.originalName) { product in
                        ProductSelectionRow(
                            product: product,
                            isSelected: selectedProducts.contains(product.originalName)
                        ) {
                            toggleSelection(product)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add Selected") {
                        addSelectedProducts()
                    }
                    .disabled(selectedProducts.isEmpty)
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        selectAll()
                    } label: {
                        HStack {
                            Image(systemName: selectedProducts.count == matchedProducts.count ? "checkmark.square.fill" : "square")
                            Text("Select All")
                        }
                    }
                }
            }
            .alert("Products Added", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Successfully added \(addedCount) products to inventory")
            }
        }
        .onAppear {
            // Автоматически выбираем продукты с высокой уверенностью
            for product in matchedProducts {
                if product.confidence == .exact || product.confidence == .high {
                    selectedProducts.insert(product.originalName)
                }
            }
        }
    }
    
    // MARK: - Methods
    
    private func toggleSelection(_ product: MatchedProduct) {
        if selectedProducts.contains(product.originalName) {
            selectedProducts.remove(product.originalName)
        } else {
            selectedProducts.insert(product.originalName)
        }
    }
    
    private func selectAll() {
        if selectedProducts.count == matchedProducts.count {
            selectedProducts.removeAll()
        } else {
            selectedProducts = Set(matchedProducts.map { $0.originalName })
        }
    }
    
    private func addSelectedProducts() {
        addedCount = 0
        
        for product in matchedProducts {
            if selectedProducts.contains(product.originalName) {
                // Определяем количественный статус на основе quantity
                let status: ProductQuantityStatus
                if product.quantity >= 1.0 {
                    status = .plenty
                } else if product.quantity >= 0.5 {
                    status = .medium
                } else {
                    status = .runningOut
                }
                
                // Определяем категорию
                let category = determineCategory(for: product.matchedIngredient)
                
                let newProduct = Product(
                    name: product.matchedIngredient,
                    quantityStatus: status
                )
                newProduct.category = category
                
                modelContext.insert(newProduct)
                addedCount += 1
            }
        }
        
        showSuccessAlert = true
    }
    
    private func determineCategory(for ingredient: String) -> String {
        if KnownIngredients.vegetables.contains(ingredient) {
            return "Vegetables"
        } else if KnownIngredients.fruits.contains(ingredient) {
            return "Fruits"
        } else if KnownIngredients.meat.contains(ingredient) {
            return "Meat"
        } else if KnownIngredients.seafood.contains(ingredient) {
            return "Seafood"
        } else if KnownIngredients.dairy.contains(ingredient) {
            return "Dairy"
        } else if KnownIngredients.grains.contains(ingredient) {
            return "Grains"
        } else if KnownIngredients.spices.contains(ingredient) {
            return "Spices"
        } else {
            return "Other"
        }
    }
}

// MARK: - Product Selection Row

struct ProductSelectionRow: View {
    let product: MatchedProduct
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .blue : .gray.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 6) {
                    // Original name from receipt
                    Text(product.originalName)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                    
                    // Matched ingredient
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(product.matchedIngredient)
                            .font(.subheadline)
                            .foregroundStyle(.blue)
                        
                        // Confidence badge
                        confidenceBadge
                    }
                    
                    // Price and quantity
                    HStack(spacing: 12) {
                        Label("\(product.price)₽", systemImage: "rublesign.circle")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        if product.quantity != 1.0 {
                            Label(String(format: "%.2f", product.quantity), systemImage: "scalemass")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private var confidenceBadge: some View {
        let (icon, color, text) = confidenceInfo
        
        HStack(spacing: 3) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption2)
        .foregroundStyle(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
    
    private var confidenceInfo: (String, Color, String) {
        switch product.confidence {
        case .exact:
            return ("checkmark.seal.fill", .green, "Exact")
        case .high:
            return ("checkmark.circle.fill", .blue, "High")
        case .medium:
            return ("questionmark.circle.fill", .orange, "Medium")
        case .low:
            return ("exclamationmark.circle.fill", .red, "Low")
        }
    }
}

#Preview {
    let mockProducts = [
        MatchedProduct(
            originalName: "Молоко 3.2% 1л",
            matchedIngredient: "Milk",
            confidence: .exact,
            price: 89,
            quantity: 1.0
        ),
        MatchedProduct(
            originalName: "Помидоры свежие 1кг",
            matchedIngredient: "Tomatoes",
            confidence: .high,
            price: 250,
            quantity: 0.5
        ),
        MatchedProduct(
            originalName: "Курица охлажденная 1кг",
            matchedIngredient: "Chicken",
            confidence: .exact,
            price: 280,
            quantity: 1.2
        )
    ]
    
    ReceiptProductsSelectionView(matchedProducts: mockProducts)
        .modelContainer(for: Product.self, inMemory: true)
}
