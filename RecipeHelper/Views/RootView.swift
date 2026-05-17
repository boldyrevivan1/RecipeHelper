import SwiftUI

struct RootView: View {
    @ObservedObject private var auth = AuthService.shared
    @ObservedObject private var fs   = FirestoreService.shared

    @State private var isLoadingProfile = true

    private var needsOnboarding: Bool {
        auth.isLoggedIn && !isLoadingProfile && fs.profile == nil
    }

    var body: some View {
        Group {
            if auth.isLoggedIn {
                if isLoadingProfile {
                    SplashView()
                } else if needsOnboarding {
                    OnboardingView()
                } else {
                    MainTabView()
                }
            } else if auth.needsEmailVerification {
                EmailVerificationView()
            } else {
                AuthView()
                    .onAppear { fs.stopListening() }
            }
        }
        .onChange(of: auth.isLoggedIn) { _, loggedIn in
            if loggedIn {
                isLoadingProfile = true
                fs.startListening()

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isLoadingProfile = false
                }
            } else {
                fs.stopListening()
                isLoadingProfile = true
            }
        }
        .onAppear {
            if auth.isLoggedIn {
                fs.startListening()
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isLoadingProfile = false
                }
            } else {
                isLoadingProfile = false
            }
        }
    }
}

struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 90))
                .foregroundStyle(.blue)
                .scaleEffect(scale)
                .opacity(opacity)

            Text("RecipeHelper")
                .font(.largeTitle).fontWeight(.bold)
                .opacity(opacity)

            ProgressView()
                .tint(.blue)
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.4)) {
                scale   = 1.0
                opacity = 1.0
            }
        }
    }
}
