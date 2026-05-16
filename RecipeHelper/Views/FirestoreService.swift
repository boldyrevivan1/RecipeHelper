//
//  FirestoreService.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 21.04.2026.
//

//
//  FirestoreService.swift
//  RecipeHelper
//
//  Handles all Firestore read/write operations.
//  User-specific data: products, shoppingList, history, profile.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

// MARK: - Firestore Models (Codable)

struct FSProduct: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var quantityStatus: String   // "Plenty" | "Medium"
    var expirationDate: Date?
    var addedDate: Date
    var category: String?
}

struct FSShoppingItem: Identifiable, Codable {
    @DocumentID var id: String?
    var ingredientName: String
    var quantity: Double
    var unit: String
    var isPurchased: Bool
    var addedDate: Date
    var recipeName: String?
}

struct FSCookingHistory: Identifiable, Codable {
    @DocumentID var id: String?
    var recipeTitle: String
    var recipeImageURL: String?
    var cuisineType: String?
    var cookedAt: Date
}

struct FSProfile: Codable {
    var displayName: String
    var email: String
    var dietaryPreferences: [String]
    var allergies: [String]
    var calorieLimit: Int?
}

struct FSPantryItem: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var isAvailable: Bool
    var isCustom: Bool = false   // true для добавленных пользователем, false для дефолтных
}

// MARK: - Service

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()

    private let db = Firestore.firestore()

    @Published var products:     [FSProduct]      = []
    @Published var shoppingList: [FSShoppingItem] = []
    @Published var history:      [FSCookingHistory] = []
    @Published var profile:      FSProfile?       = nil
    @Published var pantry:       [FSPantryItem]   = []

    private var listeners: [ListenerRegistration] = []
    private init() {}

    private var userId: String? { Auth.auth().currentUser?.uid }

    private func userRef() -> DocumentReference? {
        guard let uid = userId else { return nil }
        return db.collection("users").document(uid)
    }

    // MARK: - Start / Stop Listening

    func startListening() {
        guard let ref = userRef() else { return }
        stopListening()

        // Products
        let p = ref.collection("products")
            .addSnapshotListener { [weak self] snap, _ in
                let products = snap?.documents.compactMap {
                    try? $0.data(as: FSProduct.self)
                } ?? []
                self?.products = products
                Task { await NotificationService.shared.scheduleNotifications(for: products) }
            }

        // Shopping list
        let s = ref.collection("shoppingList")
            .order(by: "addedDate", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                self?.shoppingList = snap?.documents.compactMap {
                    try? $0.data(as: FSShoppingItem.self)
                } ?? []
            }

        // History
        let h = ref.collection("history")
            .order(by: "cookedAt", descending: true)
            .addSnapshotListener { [weak self] snap, _ in
                self?.history = snap?.documents.compactMap {
                    try? $0.data(as: FSCookingHistory.self)
                } ?? []
            }

        // Profile
        let pr = ref.collection("profile").document("data")
            .addSnapshotListener { [weak self] snap, _ in
                self?.profile = try? snap?.data(as: FSProfile.self)
            }

        // Pantry (specie inventory)
        let pa = ref.collection("pantry")
            .order(by: "name")
            .addSnapshotListener { [weak self] snap, _ in
                self?.pantry = snap?.documents.compactMap {
                    try? $0.data(as: FSPantryItem.self)
                } ?? []
                Task { await self?.seedPantryIfNeeded() }
            }

        listeners = [p, s, h, pr, pa]
    }

    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners = []
    }

    // MARK: - Products

    func addProduct(_ product: FSProduct) async throws {
        guard let ref = userRef() else { return }
        try ref.collection("products").addDocument(from: product)
    }

    func updateProduct(_ product: FSProduct) async throws {
        guard let ref = userRef(), let id = product.id else { return }
        try ref.collection("products").document(id).setData(from: product)
    }

    func deleteProduct(id: String) async throws {
        guard let ref = userRef() else { return }
        try await ref.collection("products").document(id).delete()
    }

    // MARK: - Shopping List

    func addShoppingItem(_ item: FSShoppingItem) async throws {
        guard let ref = userRef() else { return }
        try ref.collection("shoppingList").addDocument(from: item)
    }

    func toggleShoppingItem(id: String, isPurchased: Bool) async throws {
        guard let ref = userRef() else { return }
        try await ref.collection("shoppingList").document(id)
            .updateData(["isPurchased": isPurchased])
    }

    func deleteShoppingItem(id: String) async throws {
        guard let ref = userRef() else { return }
        try await ref.collection("shoppingList").document(id).delete()
    }

    func clearPurchasedItems() async throws {
        guard let ref = userRef() else { return }
        let purchased = shoppingList.filter { $0.isPurchased }
        for item in purchased {
            if let id = item.id {
                try await ref.collection("shoppingList").document(id).delete()
            }
        }
    }

    // MARK: - Cooking History

    func addHistory(recipeTitle: String, imageURL: String?, cuisine: String?) async throws {
        guard let ref = userRef() else { return }
        let entry = FSCookingHistory(
            recipeTitle: recipeTitle,
            recipeImageURL: imageURL,
            cuisineType: cuisine,
            cookedAt: Date()
        )
        try ref.collection("history").addDocument(from: entry)
    }

    func deleteHistory(id: String) async throws {
        guard let ref = userRef() else { return }
        try await ref.collection("history").document(id).delete()
    }

    // MARK: - Profile

    func saveProfile(_ profile: FSProfile) async throws {
        guard let ref = userRef() else { return }
        try ref.collection("profile").document("data").setData(from: profile)
    }

    // MARK: - Pantry

    private var pantryDidSeed = false

    func seedPantryIfNeeded() async {
        guard !pantryDidSeed, pantry.isEmpty, let ref = userRef() else { return }
        pantryDidSeed = true
        let defaults = ["Salt", "Black Pepper", "Sugar"]
        for name in defaults {
            let item = FSPantryItem(name: name, isAvailable: true, isCustom: false)
            _ = try? ref.collection("pantry").addDocument(from: item)
        }
    }

    /// Used by the onboarding flow: caller provides a final list of spice names
    /// the user has at home. Any existing pantry entries are wiped first so the
    /// user's choice is authoritative (and no duplicates sneak in from the seed).
    func replacePantry(with names: [String]) async throws {
        guard let ref = userRef() else { return }
        // mark seed as done so no auto-seed races with us
        pantryDidSeed = true

        // wipe existing
        let snap = try await ref.collection("pantry").getDocuments()
        for doc in snap.documents {
            try await doc.reference.delete()
        }

        // the 3 built-ins we know about; everything else is marked custom
        let builtIns: Set<String> = ["salt", "black pepper", "sugar"]
        for name in names {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let item = FSPantryItem(
                name: trimmed,
                isAvailable: true,
                isCustom: !builtIns.contains(trimmed.lowercased())
            )
            _ = try? ref.collection("pantry").addDocument(from: item)
        }
    }

    func togglePantryItem(id: String, isAvailable: Bool) async throws {
        guard let ref = userRef() else { return }
        try await ref.collection("pantry").document(id)
            .updateData(["isAvailable": isAvailable])
    }

    func addPantryItem(name: String) async throws {
        guard let ref = userRef() else { return }
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        // anti-duplicate (case-insensitive)
        let exists = pantry.contains { $0.name.lowercased() == trimmed.lowercased() }
        guard !exists else { return }
        let item = FSPantryItem(name: trimmed, isAvailable: true, isCustom: true)
        try ref.collection("pantry").addDocument(from: item)
    }

    func deletePantryItem(id: String) async throws {
        guard let ref = userRef() else { return }
        try await ref.collection("pantry").document(id).delete()
    }
}
