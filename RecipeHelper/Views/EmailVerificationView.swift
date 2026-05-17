import SwiftUI

struct EmailVerificationView: View {
    @ObservedObject private var auth = AuthService.shared
    @State private var checking = false
    @State private var resent   = false
    @State private var message  = ""

    var email: String {
        auth.currentUser?.email ?? "your email"
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "envelope.badge.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text("Verify your email")
                    .font(.title2).fontWeight(.bold)

                Text("We sent a verification link to:")
                    .font(.subheadline).foregroundStyle(.secondary)

                Text(email)
                    .font(.subheadline).fontWeight(.semibold)
                    .foregroundStyle(.blue)

                Text("Open the link in the email, then come back here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.green)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {

                Button {
                    Task {
                        checking = true
                        let verified = await auth.checkVerification()
                        checking = false
                        if !verified {
                            message = "Email not verified yet. Please check your inbox."
                        }
                    }
                } label: {
                    HStack {
                        if checking { ProgressView().tint(.white) }
                        Text("I've verified my email")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(checking)

                Button {
                    Task {
                        resent = await auth.resendVerification()
                        if resent { message = "Verification email resent!" }
                    }
                } label: {
                    Text("Resend email")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }

                Button {
                    auth.signOut()
                } label: {
                    Text("Use a different account")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()
        }
    }
}
