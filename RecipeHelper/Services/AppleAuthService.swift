//
//  AppleAuthService.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation
import AuthenticationServices
import SwiftUI

@Observable
class AppleAuthService: NSObject {
    static let shared = AppleAuthService()
    
    var currentUser: AppleUser?
    var isAuthenticated: Bool {
        currentUser != nil
    }
    
    private override init() {
        super.init()
        // Проверяем сохраненного пользователя
        loadUser()
    }
    
    // MARK: - Sign In
    
    func signIn() {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
    
    // MARK: - Sign Out
    
    func signOut() {
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: "appleUserID")
        UserDefaults.standard.removeObject(forKey: "appleUserName")
        UserDefaults.standard.removeObject(forKey: "appleUserEmail")
    }
    
    // MARK: - Private Methods
    
    private func saveUser(_ user: AppleUser) {
        self.currentUser = user
        UserDefaults.standard.set(user.id, forKey: "appleUserID")
        UserDefaults.standard.set(user.name, forKey: "appleUserName")
        UserDefaults.standard.set(user.email, forKey: "appleUserEmail")
    }
    
    private func loadUser() {
        guard let id = UserDefaults.standard.string(forKey: "appleUserID") else { return }
        let name = UserDefaults.standard.string(forKey: "appleUserName")
        let email = UserDefaults.standard.string(forKey: "appleUserEmail")
        
        currentUser = AppleUser(id: id, name: name, email: email)
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleAuthService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            let fullName = appleIDCredential.fullName
            let email = appleIDCredential.email
            
            // Формируем имя
            var userName: String?
            if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
                userName = "\(givenName) \(familyName)"
            } else if let givenName = fullName?.givenName {
                userName = givenName
            }
            
            let user = AppleUser(
                id: userID,
                name: userName,
                email: email
            )
            
            saveUser(user)
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print("Sign in with Apple failed: \(error.localizedDescription)")
    }
}

// MARK: - User Model

struct AppleUser {
    let id: String
    let name: String?
    let email: String?
    
    var displayName: String {
        name ?? "User"
    }
}
