//
//  InventoryView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct InventoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Product.addedDate, order: .reverse) private var products: [Product]
    @State private var showingAddProduct = false
    
    var body: some View {
        NavigationStack {
            List {
                if products.isEmpty {
                    ContentUnavailableView(
                        "No Products",
                        systemImage: "refrigerator",
                        description: Text("Add products you have at home")
                    )
                } else {
                    ForEach(products) { product in
                        ProductRow(product: product)
                    }
                    .onDelete(perform: deleteProducts)
                }
            }
            .navigationTitle("My Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddProduct) {
                AddProductView()
            }
        }
    }
    
    private func deleteProducts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(products[index])
            }
        }
    }
}

struct ProductRow: View {
    let product: Product
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                HStack {
                    // Статус количества с иконкой и цветом
                    Image(systemName: product.quantityStatus.icon)
                        .foregroundStyle(product.quantityStatus.color)
                    Text(product.quantityStatus.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(product.quantityStatus.color)
                    
                    if let category = product.category {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(category)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if let expirationDate = product.expirationDate {
                    HStack(spacing: 4) {
                        Image(systemName: product.isExpired ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.caption)
                        Text("Exp: \(expirationDate, style: .date)")
                            .font(.caption)
                    }
                    .foregroundStyle(product.isExpired ? .red : product.isExpiringSoon ? .orange : .secondary)
                }
            }
            
            Spacer()
            
            // Большая иконка статуса справа
            Image(systemName: product.quantityStatus.icon)
                .font(.title2)
                .foregroundStyle(product.quantityStatus.color)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: Product.self, inMemory: true)
}
