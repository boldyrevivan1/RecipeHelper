//
//  AppleSignInView.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInView: View {
    @State private var authService = AppleAuthService.shared
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Logo and Title
            VStack(spacing: 20) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.blue)
                
                Text("RecipeHelper")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your personal cooking assistant")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(icon: "refrigerator", title: "Track Your Inventory", description: "Keep track of what you have at home")
                FeatureRow(icon: "book.fill", title: "Discover Recipes", description: "Find recipes based on your ingredients")
                FeatureRow(icon: "cart.fill", title: "Shopping Lists", description: "Auto-generate shopping lists")
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // DEBUG: Test button (remove in production)
            Button("Skip Sign In (Test Mode)") {
                // Создаем тестового пользователя
                let testUser = AppleUser(
                    id: "test-user-123",
                    name: "Test User",
                    email: "test@example.com"
                )
                
                UserDefaults.standard.set(testUser.id, forKey: "appleUserID")
                UserDefaults.standard.set(testUser.name, forKey: "appleUserName")
                UserDefaults.standard.set(testUser.email, forKey: "appleUserEmail")
                
                authService.currentUser = testUser
            }
            .buttonStyle(.bordered)
            .padding(.bottom, 10)
            
            // Sign In Button
            SignInWithAppleButton(
                onRequest: { request in
                    request.requestedScopes = [.fullName, .email]
                },
                onCompletion: { result in
                    switch result {
                    case .success(let authorization):
                        handleAuthorization(authorization)
                    case .failure(let error):
                        print("Sign in failed: \(error.localizedDescription)")
                    }
                }
            )
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
    }
    
    private func handleAuthorization(_ authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            var userName: String?
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                userName = "\(givenName) \(familyName)"
            } else if let givenName = fullName?.givenName {
                userName = givenName
            }
            
            let user = AppleUser(id: userID, name: userName, email: email)
            
            // Save user
            UserDefaults.standard.set(user.id, forKey: "appleUserID")
            UserDefaults.standard.set(user.name, forKey: "appleUserName")
            UserDefaults.standard.set(user.email, forKey: "appleUserEmail")
            
            authService.currentUser = user
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AppleSignInView()
}
