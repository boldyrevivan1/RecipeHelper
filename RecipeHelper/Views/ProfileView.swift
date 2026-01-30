//
//  ProfileView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var users: [User]
    
    @State private var showingEditProfile = false
    
    var currentUser: User? {
        users.first
    }
    
    var body: some View {
        NavigationStack {
            if let user = currentUser, let profile = user.profile {
                // Profile exists
                List {
                    // User information section
                    Section {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(.blue)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.username)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(user.email)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.leading, 8)
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Dietary preferences
                    Section("Dietary Preferences") {
                        if profile.dietaryPreferences.isEmpty {
                            Text("Not specified")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(profile.dietaryPreferences, id: \.self) { preference in
                                Label(preference, systemImage: "leaf.fill")
                            }
                        }
                    }
                    
                    // Allergies
                    Section("Allergies & Restrictions") {
                        if profile.allergies.isEmpty {
                            Text("Not specified")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(profile.allergies, id: \.self) { allergy in
                                Label(allergy, systemImage: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                    
                    // Calories
                    Section("Daily Calorie Limit") {
                        if let calorieLimit = profile.calorieLimit {
                            HStack {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.orange)
                                Text("\(calorieLimit) kcal")
                            }
                        } else {
                            Text("Not set")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Statistics
                    Section("Statistics") {
                        HStack {
                            Label("Products in inventory", systemImage: "refrigerator")
                            Spacer()
                            Text("\(user.products?.count ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                        
                        HStack {
                            Label("Registration date", systemImage: "calendar")
                            Spacer()
                            Text(user.createdAt, style: .date)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .navigationTitle("Profile")
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingEditProfile = true
                        } label: {
                            Text("Edit")
                        }
                    }
                }
                .sheet(isPresented: $showingEditProfile) {
                    EditProfileView(user: user, profile: profile)
                }
            } else {
                // Profile not created
                CreateProfileView()
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [User.self, Profile.self], inMemory: true)
}
