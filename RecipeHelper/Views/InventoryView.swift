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
    @Query(sort: \Product.name) private var products: [Product]
    
    @State private var showAddProduct = false
    @State private var showQRScanner = false
    @State private var scannedQRCode: String?
    @State private var isProcessingReceipt = false
    @State private var matchedProducts: [MatchedProduct]?
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if products.isEmpty {
                    ContentUnavailableView(
                        "No Products",
                        systemImage: "refrigerator",
                        description: Text("Add products to start tracking your inventory")
                    )
                } else {
                    productsList
                }
            }
            .navigationTitle("Inventory")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showAddProduct = true
                        } label: {
                            Label("Add Manually", systemImage: "plus.circle")
                        }
                        
                        Button {
                            showQRScanner = true
                        } label: {
                            Label("Scan Receipt QR", systemImage: "qrcode.viewfinder")
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $showAddProduct) {
                AddProductView()
            }
            .sheet(isPresented: $showQRScanner) {
                QRScannerView(scannedCode: $scannedQRCode)
            }
            .sheet(isPresented: Binding(
                get: { matchedProducts != nil },
                set: { if !$0 { matchedProducts = nil } }
            )) {
                if let products = matchedProducts {
                    ReceiptProductsSelectionView(matchedProducts: products)
                }
            }
            .overlay {
                if isProcessingReceipt {
                    ZStack {
                        Color.black.opacity(0.4)
                            .ignoresSafeArea()
                        
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Processing receipt...")
                                .font(.headline)
                                .foregroundStyle(.white)
                        }
                        .padding(24)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                }
            }
            .onChange(of: scannedQRCode) { oldValue, newValue in
                if let qrCode = newValue {
                    processReceipt(qrCode: qrCode)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private var productsList: some View {
        List {
            ForEach(products) { product in
                ProductRow(product: product)
            }
            .onDelete(perform: deleteProducts)
        }
    }
    
    private func deleteProducts(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(products[index])
        }
    }
    
    private func processReceipt(qrCode: String) {
        print("🎯 Processing receipt with QR: \(qrCode)")
        isProcessingReceipt = true
        
        Task {
            do {
                // Парсим QR-код
                guard let receiptData = FNSReceiptService.shared.parseQRCode(qrCode) else {
                    await MainActor.run {
                        errorMessage = "Invalid QR code format"
                        showError = true
                        isProcessingReceipt = false
                    }
                    return
                }
                
                print("📄 Receipt data parsed successfully")
                
                // Получаем данные чека
                let receipt = try await FNSReceiptService.shared.fetchReceipt(data: receiptData)
                
                print("🛒 Receipt fetched: \(receipt.document.receipt.items.count) items")
                
                // Сопоставляем продукты
                let matched = FNSReceiptService.shared.matchProducts(receiptItems: receipt.document.receipt.items)
                
                await MainActor.run {
                    if matched.isEmpty {
                        errorMessage = "No food products found in receipt"
                        showError = true
                    } else {
                        print("✅ Showing \(matched.count) matched products")
                        matchedProducts = matched
                    }
                    isProcessingReceipt = false
                    scannedQRCode = nil
                }
                
            } catch {
                print("❌ Error processing receipt: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showError = true
                    isProcessingReceipt = false
                    scannedQRCode = nil
                }
            }
        }
    }
}

struct ProductRow: View {
    let product: Product
    
    var body: some View {
        HStack(spacing: 12) {
            // Status icon
            Image(systemName: product.quantityStatus.icon)
                .font(.title2)
                .foregroundStyle(product.quantityStatus.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                
                HStack(spacing: 8) {
                    if let category = product.category {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let expirationDate = product.expirationDate {
                        Text("•")
                            .foregroundStyle(.secondary)
                        
                        Image(systemName: product.isExpired ? "exclamationmark.triangle.fill" : "calendar")
                            .font(.caption)
                        Text("Exp: \(expirationDate, style: .date)")
                            .font(.caption)
                    }
                }
                .foregroundStyle(product.isExpired ? .red : product.isExpiringSoon ? .orange : .secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    InventoryView()
        .modelContainer(for: Product.self, inMemory: true)
}
