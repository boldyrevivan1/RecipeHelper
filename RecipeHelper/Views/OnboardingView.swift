import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var fs   = FirestoreService.shared
    @ObservedObject private var auth = AuthService.shared

    @State private var page = 0
    @State private var selectedDietary:  Set<String> = []
    @State private var selectedAllergies: Set<String> = []
    @State private var selectedPantry:   Set<String> = ["Salt", "Black Pepper", "Sugar"]
    @State private var customPantry:     [String]    = []
    @State private var showAddSpice      = false
    @State private var newSpiceName      = ""
    @State private var isSaving = false

    private let dietaryOptions = [
        ("🥗", "Vegetarian",  "No meat or fish"),
        ("🌱", "Vegan",       "No animal products"),
        ("🌾", "Gluten-Free", "No wheat or gluten"),
        ("🥛", "Lactose-Free","No dairy products"),
    ]

    private let allergyOptions = [
        ("🥜", "Nuts",      "Tree nuts & peanuts"),
        ("🥚", "Eggs",      "All egg products"),
        ("🐟", "Fish",      "All fish"),
        ("🦐", "Shellfish", "Shrimp, crab, lobster"),
        ("🫘", "Soy",       "Soy & soy products"),
        ("🌻", "Sesame",    "Sesame seeds & oil"),
    ]

    private let pantryOptions = [
        ("🧂", "Salt",          "Table / sea"),
        ("🌶️", "Black Pepper",  "Ground"),
        ("🍬", "Sugar",         "White / brown"),
    ]

    private let totalPages = 4

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 8) {
                ForEach(0..<totalPages, id: \.self) { i in
                    Capsule()
                        .fill(i == page ? Color.blue : Color(.systemGray4))
                        .frame(width: i == page ? 24 : 8, height: 8)
                        .animation(.spring(), value: page)
                }
            }
            .padding(.top, 20)

            TabView(selection: $page) {
                welcomePage.tag(0)
                dietaryPage.tag(1)
                allergiesPage.tag(2)
                pantryPage.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: page)

            Button { handleNext() } label: {
                HStack {
                    if isSaving { ProgressView().tint(.white) }
                    Text(page == totalPages - 1 ? "Get Started 🚀" : "Continue")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity).padding()
                .background(Color.blue).foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(isSaving)
            .padding(.horizontal, 24).padding(.bottom, 32)
        }
        .interactiveDismissDisabled()
        .alert("Add spice", isPresented: $showAddSpice) {
            TextField("Name (e.g. Paprika)", text: $newSpiceName)
                .textInputAutocapitalization(.words)
            Button("Cancel", role: .cancel) { newSpiceName = "" }
            Button("Add") {
                let name = newSpiceName.trimmingCharacters(in: .whitespacesAndNewlines)
                newSpiceName = ""
                guard !name.isEmpty else { return }

                let existing = Set(
                    (pantryOptions.map { $0.1 } + customPantry).map { $0.lowercased() }
                )
                guard !existing.contains(name.lowercased()) else { return }
                customPantry.append(name)
                selectedPantry.insert(name)
            }
        }
    }

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 100)).foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text("Welcome, \(auth.currentUser?.displayName ?? "Chef")! 👋")
                    .font(.title).fontWeight(.bold).multilineTextAlignment(.center)
                Text("Let's personalize your experience so we can suggest the best recipes for you.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 32)
            }
            Spacer()
        }
    }

    private var dietaryPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Dietary Preferences").font(.title2).fontWeight(.bold)
                Text("We'll filter recipes to match your lifestyle. You can change this anytime.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(dietaryOptions, id: \.1) { emoji, name, desc in
                        PreferenceChip(
                            emoji: emoji, name: name, desc: desc,
                            isSelected: selectedDietary.contains(name)
                        ) {
                            if selectedDietary.contains(name) { selectedDietary.remove(name) }
                            else { selectedDietary.insert(name) }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var allergiesPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Food Allergies").font(.title2).fontWeight(.bold)
                Text("We'll warn you if a recipe contains allergens. Skip if none apply.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(allergyOptions, id: \.1) { emoji, name, desc in
                        PreferenceChip(
                            emoji: emoji, name: name, desc: desc,
                            isSelected: selectedAllergies.contains(name)
                        ) {
                            if selectedAllergies.contains(name) { selectedAllergies.remove(name) }
                            else { selectedAllergies.insert(name) }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var pantryPage: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Your Pantry").font(.title2).fontWeight(.bold)
                Text("Spices you always have at home. We won't add them to your shopping list or ask to deduct them after cooking.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).padding(.horizontal, 24)
            }
            .padding(.top, 24)

            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(pantryOptions, id: \.1) { emoji, name, desc in
                        PreferenceChip(
                            emoji: emoji, name: name, desc: desc,
                            isSelected: selectedPantry.contains(name)
                        ) {
                            if selectedPantry.contains(name) { selectedPantry.remove(name) }
                            else { selectedPantry.insert(name) }
                        }
                    }

                    ForEach(customPantry, id: \.self) { name in
                        PreferenceChip(
                            emoji: "🌿", name: name, desc: "Custom",
                            isSelected: selectedPantry.contains(name)
                        ) {
                            if selectedPantry.contains(name) { selectedPantry.remove(name) }
                            else { selectedPantry.insert(name) }
                        }
                    }

                    Button { showAddSpice = true } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title).foregroundStyle(.blue)
                            Text("Add spice").font(.subheadline).fontWeight(.semibold)
                                .foregroundStyle(.blue)
                            Text("Your own").font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.blue.opacity(0.06))
                        .overlay(RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 1.5, dash: [5])))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func handleNext() {
        if page < totalPages - 1 { withAnimation { page += 1 } }
        else { saveAndFinish() }
    }

    private func saveAndFinish() {
        isSaving = true
        let profile = FSProfile(
            displayName: auth.currentUser?.displayName ?? "",
            email:       auth.currentUser?.email ?? "",
            dietaryPreferences: Array(selectedDietary),
            allergies:          Array(selectedAllergies),
            calorieLimit:       nil
        )
        let pantryNames = Array(selectedPantry)

        Task {
            try? await fs.saveProfile(profile)
            try? await fs.replacePantry(with: pantryNames)
            isSaving = false
        }
    }
}

private struct PreferenceChip: View {
    let emoji: String
    let name:  String
    let desc:  String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji).font(.title)
                Text(name).font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(isSelected ? .blue : .primary)
                Text(desc).font(.caption2).foregroundStyle(.secondary)
                    .multilineTextAlignment(.center).lineLimit(2)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.secondarySystemBackground))
            .overlay(RoundedRectangle(cornerRadius: 14)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}
