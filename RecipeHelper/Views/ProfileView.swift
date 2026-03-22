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
    @Query private var profiles: [Profile]
    
    @State private var showEditProfile = false
    
    var currentProfile: Profile? {
        profiles.first
    }
    
    var body: some View {
        NavigationStack {
            if let profile = currentProfile {
                profileContent(profile: profile)
            } else {
                CreateProfileView()
            }
        }
    }
    
    private func profileContent(profile: Profile) -> some View {
        List {
            // Profile Header
            Section {
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue)
                    
                    Text("My Profile")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            // Dietary Preferences
            Section {
                Text("Vegetarian, Vegan, Gluten-Free")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } header: {
                Text("Dietary Preferences")
            }
            
            // Allergies
            Section {
                Text("Peanuts, Shellfish")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } header: {
                Text("Allergies")
            }
            
            // Calorie Limit
            Section {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                    Text("Daily Calorie Goal")
                    Spacer()
                    Text("2000 kcal")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Nutrition Goals")
            }
        }
        .navigationTitle("Profile")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditProfile = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showEditProfile) {
            EditProfileView(profile: profile)
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: Profile.self, inMemory: true)
}
