import SwiftUI

struct ProfileView: View {
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var fs   = FirestoreService.shared

    @State private var showEditPreferences = false
    @State private var showSignOutAlert    = false

    private var userName: String  { auth.currentUser?.displayName ?? "Chef" }
    private var userEmail: String { auth.currentUser?.email ?? "" }
    private var initials: String {
        let parts = userName.split(separator: " ")
        if parts.count >= 2 { return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased() }
        return String(userName.prefix(2)).uppercased()
    }

    var body: some View {
        NavigationStack {
            List {

                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(Color.blue.gradient).frame(width: 64, height: 64)
                            Text(initials).font(.title2).fontWeight(.bold).foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            Text(userName).font(.headline)
                            Text(userEmail).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }

                if let profile = fs.profile {
                    if !profile.dietaryPreferences.isEmpty {
                        Section("Dietary Preferences") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(profile.dietaryPreferences, id: \.self) { pref in
                                        Text(pref)
                                            .font(.caption).fontWeight(.medium)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(Color.green.opacity(0.15))
                                            .foregroundStyle(.green)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }

                    if !profile.allergies.isEmpty {
                        Section("Allergies") {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(profile.allergies, id: \.self) { allergy in
                                        Text(allergy)
                                            .font(.caption).fontWeight(.medium)
                                            .padding(.horizontal, 10).padding(.vertical, 5)
                                            .background(Color.red.opacity(0.15))
                                            .foregroundStyle(.red)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Settings") {
                    Button {
                        showEditPreferences = true
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundStyle(.blue).frame(width: 28)
                            Text("Dietary Preferences & Allergies")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .foregroundStyle(.primary)
                }

                Section("Activity") {
                    NavigationLink {
                        CookingHistoryView()
                    } label: {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .foregroundStyle(.orange).frame(width: 28)
                            Text("Cooking History")
                            Spacer()
                            Text("\(fs.history.count)")
                                .foregroundStyle(.secondary).font(.subheadline)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showSignOutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .frame(width: 28)
                            Text("Sign Out")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showEditPreferences) {
                EditPreferencesView()
            }
            .alert("Sign Out", isPresented: $showSignOutAlert) {
                Button("Sign Out", role: .destructive) { auth.signOut() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .safeAreaInset(edge: .bottom) {
                if !CookingSessionManager.shared.sessions.isEmpty {
                    Color.clear.frame(height: 70)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
}
