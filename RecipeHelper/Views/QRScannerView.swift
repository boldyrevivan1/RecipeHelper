//
//  QRScannerView.swift
//  RecipeHelper
//

import SwiftUI
import PhotosUI

// MARK: - Camera Picker

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate   = context.coordinator
        return picker
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}

// MARK: - QRScannerView

@MainActor
struct QRScannerView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showCamera           = false
    @State private var showPhotoPicker      = false
    @State private var selectedPhoto:       PhotosPickerItem?
    @State private var cameraImage:         UIImage?
    @State private var isProcessing         = false
    @State private var errorMessage:        String?
    @State private var showError            = false
    @State private var recognizedProducts:  [ReceiptProduct] = []
    @State private var showProductSelection = false

    var body: some View {
        NavigationStack {
            mainContent
                .navigationTitle("Receipt Scanner")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { cancelButton }
                .fullScreenCover(isPresented: $showCamera) {
                    CameraPicker(image: $cameraImage).ignoresSafeArea()
                }
                .onChange(of: cameraImage) { _, img in if let img { processImage(img) } }
                .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
                .onChange(of: selectedPhoto) { _, item in if let item { processPickerItem(item) } }
                .sheet(isPresented: $showProductSelection) {
                    ProductSelectionSheet(products: recognizedProducts, onDismiss: { dismiss() })
                }
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) {}
                } message: { Text(errorMessage ?? "Unknown error") }
                .overlay { if isProcessing { processingOverlay } }
        }
    }

    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Cancel") { dismiss() }
        }
    }

    private var mainContent: some View {
        VStack(spacing: 32) {
            Spacer()
            Image(systemName: "doc.text.viewfinder")
                .font(.system(size: 80)).foregroundStyle(.blue)
            VStack(spacing: 10) {
                Text("Scan Receipt").font(.title2).fontWeight(.bold)
                Text("Take a photo or choose from gallery to recognise products")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal)
            }
            Spacer()
            actionButtons
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button { showCamera = true } label: {
                Label("Take Photo", systemImage: "camera.fill")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color.blue).foregroundStyle(.white).cornerRadius(12)
            }
            Button { showPhotoPicker = true } label: {
                Label("Choose from Gallery", systemImage: "photo.on.rectangle")
                    .font(.headline).frame(maxWidth: .infinity).padding()
                    .background(Color(.secondarySystemBackground))
                    .foregroundStyle(.blue).cornerRadius(12)
            }
        }
        .padding(.horizontal, 40).padding(.bottom, 40)
    }

    private var processingOverlay: some View {
        ZStack {
            Color.black.opacity(0.4).ignoresSafeArea()
            VStack(spacing: 20) {
                ProgressView().scaleEffect(1.5).tint(.white)
                Text("Recognising receipt...").font(.headline).foregroundStyle(.white)
            }
            .padding(40).background(.ultraThinMaterial).cornerRadius(20)
        }
    }

    // MARK: - Processing

    private func processImage(_ image: UIImage) {
        cameraImage = nil; isProcessing = true
        Task { defer { isProcessing = false }; await run(image: image) }
    }

    private func processPickerItem(_ item: PhotosPickerItem) {
        selectedPhoto = nil; isProcessing = true
        Task {
            defer { isProcessing = false }
            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let img  = UIImage(data: data) else { throw OCRError.invalidImage }
                await run(image: img)
            } catch { errorMessage = error.localizedDescription; showError = true }
        }
    }

    private func run(image: UIImage) async {
        do {
            let all = try await ReceiptOCRService.shared.recognizeProducts(from: image)
            let matched = all.filter { IngredientMatcher.match(russianName: $0.name) != nil }
            if matched.isEmpty {
                errorMessage = "No products recognised. Try a clearer photo."
                showError = true
            } else {
                recognizedProducts = matched
                showProductSelection = true
            }
        } catch { errorMessage = error.localizedDescription; showError = true }
    }
}

// MARK: - Product Selection Sheet

struct ProductSelectionSheet: View {
    let products:  [ReceiptProduct]
    let onDismiss: () -> Void

    @State private var rows: [ProductRowState] = []

    var selectedCount: Int { rows.filter { $0.isSelected }.count }

    var body: some View {
        NavigationStack {
            List($rows) { $row in ReceiptProductRowView(row: $row) }
                .navigationTitle("Select Products")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { onDismiss() }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Add (\(selectedCount))") { addProducts() }
                            .disabled(selectedCount == 0).fontWeight(.semibold)
                    }
                }
                .onAppear { buildRows() }
        }
    }

    private func buildRows() {
        rows = products.compactMap { product in
            guard let match = IngredientMatcher.match(russianName: product.name) else { return nil }
            return ProductRowState(product: product, match: match)
        }
        rows = rows.map { var r = $0; r.isSelected = true; return r }
    }

    private func addProducts() {
        Task {
            let existing = FirestoreService.shared.products
            for row in rows where row.isSelected {
                let name = row.match.englishName
                // Refresh existing entry instead of creating a duplicate.
                // Fresh receipt = fresh expiration date, so override previous.
                if var match = existing.first(where: {
                    $0.name.lowercased().trimmingCharacters(in: .whitespaces)
                        == name.lowercased().trimmingCharacters(in: .whitespaces)
                }) {
                    match.quantityStatus = "Plenty"
                    match.expirationDate = row.expDate
                    match.addedDate      = Date()
                    match.category       = row.match.category
                    try? await FirestoreService.shared.updateProduct(match)
                } else {
                    let product = FSProduct(
                        name: name,
                        quantityStatus: "Plenty",
                        expirationDate: row.expDate,
                        addedDate: Date(),
                        category: row.match.category
                    )
                    try? await FirestoreService.shared.addProduct(product)
                }
            }
        }
        onDismiss()
    }
}

// MARK: - Row State

struct ProductRowState: Identifiable {
    let product: ReceiptProduct
    let match:   IngredientMatch
    var isSelected = true
    var expDate:   Date

    var id: UUID { product.id }

    init(product: ReceiptProduct, match: IngredientMatch) {
        self.product = product
        self.match   = match
        self.expDate = Calendar.current.date(byAdding: .day, value: match.defaultDays, to: Date()) ?? Date()
    }
}

// MARK: - Row View

struct ReceiptProductRowView: View {
    @Binding var row: ProductRowState

    var body: some View {
        VStack(spacing: 0) {
            Button { row.isSelected.toggle() } label: {
                HStack(spacing: 12) {
                    Image(systemName: row.isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.title3).foregroundStyle(row.isSelected ? .blue : .gray)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(row.match.englishName)
                            .font(.body).fontWeight(.medium).foregroundStyle(.primary)
                        HStack(spacing: 6) {
                            Text(row.product.name).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            Text("·").foregroundStyle(.secondary)
                            Text(row.match.category).font(.caption).foregroundStyle(.blue)
                        }
                    }
                    Spacer()
                    if let price = row.product.price {
                        Text("\(price, specifier: "%.2f")₽").font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
            .buttonStyle(.plain)

            if row.isSelected {
                HStack {
                    Image(systemName: "calendar").font(.caption).foregroundStyle(.secondary)
                    Text("Expires:").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    DatePicker("", selection: $row.expDate, in: Date()..., displayedComponents: .date)
                        .labelsHidden().font(.caption)
                }
                .padding(.bottom, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.2), value: row.isSelected)
    }
}

#Preview {
    QRScannerView()
}
