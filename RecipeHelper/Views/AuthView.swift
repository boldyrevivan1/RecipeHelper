//
//  AuthView.swift
//  RecipeHelper
//

import SwiftUI

struct AuthView: View {
    @State private var mode: Mode = .signIn
    @ObservedObject private var auth = AuthService.shared

    enum Mode { case signIn, signUp, reset }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    VStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(.blue)
                        Text("RecipeHelper")
                            .font(.largeTitle).fontWeight(.bold)
                        Text("Your smart kitchen companion")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)

                    VStack(spacing: 16) {
                        switch mode {
                        case .signIn: SignInForm(onSwitch: { mode = .signUp }, onReset: { mode = .reset })
                        case .signUp: SignUpForm(onSwitch: { mode = .signIn })
                        case .reset:  ResetForm(onBack: { mode = .signIn })
                        }
                    }
                    .padding(.horizontal, 24)

                    if let error = auth.errorMessage {
                        Text(error)
                            .font(.caption).foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .padding(.bottom, 40)
            }
        }
    }
}

private struct SignInForm: View {
    let onSwitch: () -> Void
    let onReset:  () -> Void
    @ObservedObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 12) {
            AuthTextField(placeholder: "Email", text: $email, isEmail: true)
            AuthTextField(placeholder: "Password", text: $password, secure: true)
            Button { Task { await auth.signIn(email: email, password: password) } } label: {
                AuthButton(title: "Sign In", isLoading: auth.isLoading)
            }
            .disabled(email.isEmpty || password.isEmpty || auth.isLoading)
            HStack {
                Button("Forgot password?") { onReset() }.font(.caption).foregroundStyle(.blue)
                Spacer()
                Button("Create account") { onSwitch() }.font(.caption).foregroundStyle(.blue)
            }
        }
    }
}

private struct SignUpForm: View {
    let onSwitch: () -> Void
    @ObservedObject private var auth = AuthService.shared
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirm = ""
    private var passwordsMatch: Bool { password == confirm }
    private var canSubmit: Bool { !name.isEmpty && !email.isEmpty && password.count >= 6 && passwordsMatch && !auth.isLoading }

    var body: some View {
        VStack(spacing: 12) {
            AuthTextField(placeholder: "Full Name", text: $name)
            AuthTextField(placeholder: "Email", text: $email, isEmail: true)
            AuthTextField(placeholder: "Password (min 6 chars)", text: $password, secure: true)
            AuthTextField(placeholder: "Confirm Password", text: $confirm, secure: true)
            if !confirm.isEmpty && !passwordsMatch {
                Text("Passwords don't match").font(.caption).foregroundStyle(.red)
            }
            Button { Task { await auth.signUp(email: email, password: password, name: name) } } label: {
                AuthButton(title: "Create Account", isLoading: auth.isLoading)
            }
            .disabled(!canSubmit)
            Button("Already have an account? Sign In") { onSwitch() }.font(.caption).foregroundStyle(.blue)
        }
    }
}

private struct ResetForm: View {
    let onBack: () -> Void
    @ObservedObject private var auth = AuthService.shared
    @State private var email = ""
    @State private var sent = false

    var body: some View {
        VStack(spacing: 12) {
            Text("Enter your email and we'll send a reset link.")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            AuthTextField(placeholder: "Email", text: $email, isEmail: true)
            if sent { Label("Reset email sent!", systemImage: "checkmark.circle.fill").foregroundStyle(.green) }
            Button { Task { sent = await auth.resetPassword(email: email) } } label: {
                AuthButton(title: "Send Reset Link", isLoading: auth.isLoading)
            }
            .disabled(email.isEmpty || auth.isLoading)
            Button("Back to Sign In") { onBack() }.font(.caption).foregroundStyle(.blue)
        }
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    var isEmail = false
    var secure = false

    var body: some View {
        Group {
            if secure {
                SecureField(placeholder, text: $text)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(isEmail ? .emailAddress : .default)
                    .autocapitalization(isEmail ? .none : .words)
                    .disableAutocorrection(isEmail)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct AuthButton: View {
    let title: String
    let isLoading: Bool
    var body: some View {
        HStack {
            if isLoading { ProgressView().tint(.white) }
            Text(title).fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity).padding()
        .background(Color.blue).foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
