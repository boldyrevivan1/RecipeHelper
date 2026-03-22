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
    let profile: Profile
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Profile editing coming soon!")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Info")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Profile.self, configurations: config)
    
    let profile = Profile()
    container.mainContext.insert(profile)
    
    return EditProfileView(profile: profile)
        .modelContainer(container)
}
