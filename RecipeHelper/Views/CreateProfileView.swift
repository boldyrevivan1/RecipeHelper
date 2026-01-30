//
//  CreateProfileView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct CreateProfileView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var username = ""
    @State private var email = ""
    @State private var selectedDiets: Set<String> = []
    @State private var selectedAllergies: Set<String> = []
    @State private var calorieLimit = ""
    @State private var hasCalorieLimit = false
    
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
                
                Section {
                    Button("Create Profile") {
                        createProfile()
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(username.isEmpty || email.isEmpty)
                }
            }
            .navigationTitle("Create Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func createProfile() {
        // Create user
        let newUser = User(username: username, email: email)
        
        // Create profile
        let newProfile = Profile(
            dietaryPreferences: Array(selectedDiets),
            allergies: Array(selectedAllergies),
            calorieLimit: hasCalorieLimit ? Int(calorieLimit) : nil
        )
        
        // Link them
        newUser.profile = newProfile
        newProfile.user = newUser
        
        // Save
        modelContext.insert(newUser)
        modelContext.insert(newProfile)
    }
}

#Preview {
    CreateProfileView()
        .modelContainer(for: [User.self, Profile.self], inMemory: true)
}
