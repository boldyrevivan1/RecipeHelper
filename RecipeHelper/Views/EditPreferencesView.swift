import SwiftUI

struct EditPreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var fs   = FirestoreService.shared
    @ObservedObject private var auth = AuthService.shared

    @State private var selectedDietary:   Set<String> = []
    @State private var selectedAllergies: Set<String> = []
    @State private var isSaving = false

    private let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Lactose-Free"]
    private let allergyOptions = ["Nuts", "Eggs", "Fish", "Shellfish", "Soy", "Sesame"]

    private func dietaryEmoji(_ name: String) -> String {
        switch name {
        case "Vegetarian": return "🥗"
        case "Vegan":      return "🌱"
        case "Gluten-Free":return "🌾"
        case "Lactose-Free":return "🥛"
        case "Halal":      return "🕌"
        case "Kosher":     return "✡️"
        case "Keto":       return "🥩"
        case "Paleo":      return "🫚"
        default:           return "🍽️"
        }
    }

    private func allergyEmoji(_ name: String) -> String {
        switch name {
        case "Nuts":      return "🥜"
        case "Dairy":     return "🥛"
        case "Eggs":      return "🥚"
        case "Gluten":    return "🌾"
        case "Fish":      return "🐟"
        case "Shellfish": return "🦐"
        case "Soy":       return "🫘"
        case "Sesame":    return "🌻"
        default:          return "⚠️"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                infoSection
                dietarySection
                allergiesSection
                if !selectedDietary.isEmpty || !selectedAllergies.isEmpty {
                    clearSection
                }
            }
            .navigationTitle("Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                        .disabled(isSaving)
                }
            }
            .onAppear { loadCurrent() }
        }
    }

    private var infoSection: some View {
        Section {
            Text("These preferences filter recipes. You can change them anytime.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var dietarySection: some View {
        Section("Dietary Preferences") {
            ForEach(dietaryOptions, id: \.self) { name in
                Toggle(isOn: Binding(
                    get: { selectedDietary.contains(name) },
                    set: { on in
                        if on { selectedDietary.insert(name) }
                        else  { selectedDietary.remove(name) }
                    }
                )) {
                    Text("\(dietaryEmoji(name)) \(name)")
                }
            }
        }
    }

    private var allergiesSection: some View {
        Section("Allergies") {
            ForEach(allergyOptions, id: \.self) { name in
                Toggle(isOn: Binding(
                    get: { selectedAllergies.contains(name) },
                    set: { on in
                        if on { selectedAllergies.insert(name) }
                        else  { selectedAllergies.remove(name) }
                    }
                )) {
                    Text("\(allergyEmoji(name)) \(name)")
                }
            }
        }
    }

    private var clearSection: some View {
        Section {
            Button(role: .destructive) {
                selectedDietary.removeAll()
                selectedAllergies.removeAll()
            } label: {
                Label("Clear All Preferences", systemImage: "trash")
            }
        }
    }

    private func loadCurrent() {
        if let profile = fs.profile {
            selectedDietary   = Set(profile.dietaryPreferences)
            selectedAllergies = Set(profile.allergies)
        }
    }

    private func save() {
        isSaving = true
        let profile = FSProfile(
            displayName: auth.currentUser?.displayName ?? "",
            email:       auth.currentUser?.email ?? "",
            dietaryPreferences: Array(selectedDietary),
            allergies:          Array(selectedAllergies),
            calorieLimit:       fs.profile?.calorieLimit
        )
        Task {
            try? await fs.saveProfile(profile)
            isSaving = false
            dismiss()
        }
    }
}
