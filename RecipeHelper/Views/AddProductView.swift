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
    
    @State private var name = ""
    @State private var quantity = 1.0
    @State private var unit = "pcs"
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    @State private var category = "Other"
    
    let units = ["pcs", "kg", "g", "l", "ml", "pack"]
    let categories = ["Vegetables", "Fruits", "Meat", "Fish", "Dairy", "Bread", "Grains", "Spices", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Information") {
                    TextField("Name", text: $name)
                    
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
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section {
                    Toggle("Set expiration date", isOn: $hasExpirationDate)
                    
                    if hasExpirationDate {
                        DatePicker(
                            "Expiration date",
                            selection: $expirationDate,
                            in: Date()...,
                            displayedComponents: .date
                        )
                    }
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
                    Button("Add") {
                        addProduct()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func addProduct() {
        let newProduct = Product(
            name: name,
            quantity: quantity,
            unit: unit,
            expirationDate: hasExpirationDate ? expirationDate : nil,
            category: category
        )
        modelContext.insert(newProduct)
        dismiss()
    }
}

#Preview {
    AddProductView()
        .modelContainer(for: Product.self, inMemory: true)
}
