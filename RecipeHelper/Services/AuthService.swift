//
//  AuthService.swift
//  RecipeHelper
//

import Foundation
import FirebaseAuth

@MainActor
class AuthService: ObservableObject {
    static let shared = AuthService()

    @Published var currentUser: FirebaseAuth.User? = nil
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var needsEmailVerification = false

    private var handle: AuthStateDidChangeListenerHandle?

    private init() {
        currentUser = Auth.auth().currentUser
        handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.currentUser = user
            self?.needsEmailVerification = user != nil && !(user?.isEmailVerified ?? false)
        }
    }

    var isLoggedIn: Bool {
        guard let user = currentUser else { return false }
        return user.isEmailVerified
    }

    // MARK: - Sign Up

    func signUp(email: String, password: String, name: String) async -> Bool {
        isLoading = true; errorMessage = nil
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let req = result.user.createProfileChangeRequest()
            req.displayName = name
            try await req.commitChanges()

            // Send verification email
            try await result.user.sendEmailVerification()

            currentUser = result.user
            needsEmailVerification = true
            isLoading = false
            return true
        } catch {
            errorMessage = friendlyError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Sign In

    func signIn(email: String, password: String) async -> Bool {
        isLoading = true; errorMessage = nil
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            currentUser = result.user

            if !result.user.isEmailVerified {
                needsEmailVerification = true
                isLoading = false
                return false
            }

            needsEmailVerification = false
            isLoading = false
            return true
        } catch {
            errorMessage = friendlyError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Resend Verification

    func resendVerification() async -> Bool {
        do {
            try await currentUser?.sendEmailVerification()
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    // MARK: - Check Verification

    func checkVerification() async -> Bool {
        do {
            try await currentUser?.reload()
            let verified = currentUser?.isEmailVerified ?? false
            needsEmailVerification = !verified
            return verified
        } catch {
            return false
        }
    }

    // MARK: - Sign Out

    func signOut() {
        try? Auth.auth().signOut()
        currentUser = nil
        needsEmailVerification = false
    }

    // MARK: - Reset Password

    func resetPassword(email: String) async -> Bool {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            return true
        } catch {
            errorMessage = friendlyError(error)
            return false
        }
    }

    private func friendlyError(_ error: Error) -> String {
        guard let errCode = AuthErrorCode(rawValue: (error as NSError).code) else {
            return error.localizedDescription
        }
        switch errCode {
        case .emailAlreadyInUse:  return "This email is already registered."
        case .invalidEmail:       return "Please enter a valid email."
        case .weakPassword:       return "Password must be at least 6 characters."
        case .wrongPassword:      return "Incorrect password."
        case .userNotFound:       return "No account found with this email."
        case .networkError:       return "Network error. Check your connection."
        default:                  return error.localizedDescription
        }
    }
}
