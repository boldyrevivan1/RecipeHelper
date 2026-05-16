//
//  EditProductView.swift
//  RecipeHelper
//

import SwiftUI

struct EditProductView: View {
    @Environment(\.dismiss) private var dismiss
    @State var product: FSProduct

    @State private var hasExpirationDate: Bool
    @State private var expirationDate: Date

    private let allCategories = [
        "Meat","Seafood","Dairy","Vegetables","Fruits",
        "Bakery","Grains","Oils","Sauces","Spices",
        "Baking","Nuts","Legumes","Other"
    ]

    init(product: FSProduct) {
        _product = State(initialValue: product)
        _hasExpirationDate = State(initialValue: product.expirationDate != nil)
        _expirationDate = State(initialValue: product.expirationDate ?? Date())
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    HStack {
                        Text(product.name).font(.headline)
                        Spacer()
                        Text(product.category ?? "Other").font(.caption).foregroundStyle(.secondary)
                    }
                }

                Section("Category") {
                    Picker("Category", selection: Binding(
                        get: { product.category ?? "Other" },
                        set: { product.category = $0 }
                    )) {
                        ForEach(allCategories, id: \.self) { Text($0).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                Section("Quantity Status") {
                    HStack(spacing: 12) {
                        ForEach(["Plenty", "Medium"], id: \.self) { status in
                            let statusColor = QuantityStatusStyle.color(for: status)
                            let statusIcon  = QuantityStatusStyle.icon(for: status)
                            Button { product.quantityStatus = status } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: statusIcon).font(.title2)
                                        .foregroundStyle(product.quantityStatus == status ? statusColor : .gray.opacity(0.4))
                                    Text(status).font(.caption)
                                        .foregroundStyle(product.quantityStatus == status ? .primary : .secondary)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 12)
                                .background(RoundedRectangle(cornerRadius: 10)
                                    .fill(product.quantityStatus == status ? statusColor.opacity(0.15) : Color.gray.opacity(0.05)))
                                .overlay(RoundedRectangle(cornerRadius: 10)
                                    .stroke(product.quantityStatus == status ? statusColor : Color.clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Section {
                    Toggle("Has expiration date", isOn: $hasExpirationDate)
                        .onChange(of: hasExpirationDate) { _, has in
                            product.expirationDate = has ? expirationDate : nil
                        }
                    if hasExpirationDate {
                        DatePicker("Expiration Date", selection: $expirationDate, in: Date()..., displayedComponents: .date)
                            .onChange(of: expirationDate) { _, date in product.expirationDate = date }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach([("Tomorrow",1),("3 days",3),("1 week",7),("2 weeks",14),("1 month",30)], id: \.0) { label, days in
                                    Button(label) {
                                        expirationDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
                                        product.expirationDate = expirationDate
                                    }
                                    .font(.caption)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color(.secondarySystemBackground))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                } header: { Text("Expiration") }
            }
            .navigationTitle("Edit Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        Task { try? await FirestoreService.shared.updateProduct(product) }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}
