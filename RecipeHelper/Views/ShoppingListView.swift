//
//  ShoppingListView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct ShoppingListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ShoppingListItem.addedDate, order: .reverse) private var items: [ShoppingListItem]
    
    @State private var showingAddItem = false
    
    var unpurchasedItems: [ShoppingListItem] {
        items.filter { !$0.isPurchased }
    }
    
    var purchasedItems: [ShoppingListItem] {
        items.filter { $0.isPurchased }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    ContentUnavailableView(
                        "Shopping List is Empty",
                        systemImage: "cart",
                        description: Text("Add items you need to buy")
                    )
                } else {
                    // Unpurchased items
                    if !unpurchasedItems.isEmpty {
                        Section("To Buy") {
                            ForEach(unpurchasedItems) { item in
                                ShoppingItemRow(item: item)
                            }
                            .onDelete { offsets in
                                deleteItems(from: unpurchasedItems, offsets: offsets)
                            }
                        }
                    }
                    
                    // Purchased items
                    if !purchasedItems.isEmpty {
                        Section("Purchased") {
                            ForEach(purchasedItems) { item in
                                ShoppingItemRow(item: item)
                            }
                            .onDelete { offsets in
                                deleteItems(from: purchasedItems, offsets: offsets)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Shopping List")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                if !purchasedItems.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Clear Purchased") {
                            clearPurchased()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddShoppingItemView()
            }
        }
    }
    
    private func deleteItems(from source: [ShoppingListItem], offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(source[index])
            }
        }
    }
    
    private func clearPurchased() {
        withAnimation {
            for item in purchasedItems {
                modelContext.delete(item)
            }
        }
    }
}

struct ShoppingItemRow: View {
    let item: ShoppingListItem
    
    var body: some View {
        HStack {
            Button {
                withAnimation {
                    item.isPurchased.toggle()
                }
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(item.isPurchased ? .green : .gray)
                    .font(.title3)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.ingredientName)
                    .font(.headline)
                    .strikethrough(item.isPurchased)
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)
                
                HStack {
                    Text("\(item.quantity, specifier: "%.1f") \(item.unit)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let recipeName = item.recipeName {
                        Text("•")
                            .foregroundStyle(.secondary)
                        Text(recipeName)
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// Add Shopping Item View
struct AddShoppingItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var ingredientName = ""
    @State private var quantity = 1.0
    @State private var unit = "pcs"
    
    let units = ["pcs", "kg", "g", "l", "ml", "pack"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Item Information") {
                    TextField("Name", text: $ingredientName)
                    
                    HStack {
                        TextField("Quantity", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                        
                        Picker("Unit", selection: $unit) {
                            ForEach(units, id: \.self) { unit in
                                Text(unit).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .navigationTitle("Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addItem()
                    }
                    .disabled(ingredientName.isEmpty)
                }
            }
        }
    }
    
    private func addItem() {
        let newItem = ShoppingListItem(
            ingredientName: ingredientName,
            quantity: quantity,
            unit: unit
        )
        modelContext.insert(newItem)
        dismiss()
    }
}

#Preview {
    ShoppingListView()
        .modelContainer(for: ShoppingListItem.self, inMemory: true)
}
