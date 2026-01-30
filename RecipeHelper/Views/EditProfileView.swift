//
//  EditProfileView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    let user: User
    let profile: Profile
    
    @State private var username: String
    @State private var email: String
    @State private var selectedDiets: Set<String>
    @State private var selectedAllergies: Set<String>
    @State private var calorieLimit: String
    @State private var hasCalorieLimit: Bool
    
    let availableDiets = [
        "Vegetarian",
        "Vegan",
        "Halal",
        "Kosher",
        "Gluten-Free",
        "Lactose-Free",
        "Keto",
        "Paleo"
    ]
    
    let commonAllergies = [
        "Milk",
        "Eggs",
        "Fish",
        "Shellfish",
        "Tree Nuts",
        "Peanuts",
        "Wheat (Gluten)",
        "Soy"
    ]
    
    init(user: User, profile: Profile) {
        self.user = user
        self.profile = profile
        
        _username = State(initialValue: user.username)
        _email = State(initialValue: user.email)
        _selectedDiets = State(initialValue: Set(profile.dietaryPreferences))
        _selectedAllergies = State(initialValue: Set(profile.allergies))
        _calorieLimit = State(initialValue: profile.calorieLimit != nil ? "\(profile.calorieLimit!)" : "")
        _hasCalorieLimit = State(initialValue: profile.calorieLimit != nil)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Personal Information") {
                    TextField("Username", text: $username)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                
                Section("Dietary Preferences") {
                    ForEach(availableDiets, id: \.self) { diet in
                        Toggle(diet, isOn: Binding(
                            get: { selectedDiets.contains(diet) },
                            set: { isSelected in
                                if isSelected {
                                    selectedDiets.insert(diet)
                                } else {
                                    selectedDiets.remove(diet)
                                }
                            }
                        ))
                    }
                }
                
                Section("Allergies") {
                    ForEach(commonAllergies, id: \.self) { allergy in
                        Toggle(allergy, isOn: Binding(
                            get: { selectedAllergies.contains(allergy) },
                            set: { isSelected in
                                if isSelected {
                                    selectedAllergies.insert(allergy)
                                } else {
                                    selectedAllergies.remove(allergy)
                                }
                            }
                        ))
                    }
                }
                
                Section("Daily Calorie Limit") {
                    Toggle("Set limit", isOn: $hasCalorieLimit)
                    
                    if hasCalorieLimit {
                        TextField("Calories (e.g., 2000)", text: $calorieLimit)
                            .keyboardType(.numberPad)
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(username.isEmpty || email.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() {
        user.username = username
        user.email = email
        
        profile.dietaryPreferences = Array(selectedDiets)
        profile.allergies = Array(selectedAllergies)
        profile.calorieLimit = hasCalorieLimit ? Int(calorieLimit) : nil
        
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, Profile.self, configurations: config)
    
    let user = User(username: "Ivan", email: "ivan@example.com")
    let profile = Profile(dietaryPreferences: ["Vegetarian"], allergies: ["Tree Nuts"], calorieLimit: 2000)
    user.profile = profile
    profile.user = user
    
    container.mainContext.insert(user)
    container.mainContext.insert(profile)
    
    return EditProfileView(user: user, profile: profile)
        .modelContainer(container)
}
