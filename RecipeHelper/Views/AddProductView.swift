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
    @State private var quantityStatus: ProductQuantityStatus = .medium
    @State private var hasExpirationDate = false
    @State private var expirationDate = Date()
    @State private var category = "Other"
    
    let categories = ["Vegetables", "Fruits", "Meat", "Fish", "Dairy", "Bread", "Grains", "Spices", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Product Information") {
                    TextField("Name", text: $name)
                    
                    Picker("Category", selection: $category) {
                        ForEach(categories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }
                }
                
                Section("Quantity Status") {
                    Picker("Status", selection: $quantityStatus) {
                        HStack {
                            Image(systemName: ProductQuantityStatus.plenty.icon)
                                .foregroundStyle(ProductQuantityStatus.plenty.color)
                            Text(ProductQuantityStatus.plenty.rawValue)
                        }
                        .tag(ProductQuantityStatus.plenty)
                        
                        HStack {
                            Image(systemName: ProductQuantityStatus.medium.icon)
                                .foregroundStyle(ProductQuantityStatus.medium.color)
                            Text(ProductQuantityStatus.medium.rawValue)
                        }
                        .tag(ProductQuantityStatus.medium)
                        
                        HStack {
                            Image(systemName: ProductQuantityStatus.runningOut.icon)
                                .foregroundStyle(ProductQuantityStatus.runningOut.color)
                            Text(ProductQuantityStatus.runningOut.rawValue)
                        }
                        .tag(ProductQuantityStatus.runningOut)
                        
                       
                    }
                    .pickerStyle(.navigationLink)
                    
                    // Preview выбранного статуса
                    HStack {
                        Image(systemName: quantityStatus.icon)
                            .foregroundStyle(quantityStatus.color)
                            .font(.title2)
                        Text(quantityStatus.rawValue)
                            .foregroundStyle(quantityStatus.color)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
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
            quantityStatus: quantityStatus,
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
