//
//  RecipeHelperApp.swift
//  RecipeHelper
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct RecipeHelperApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var sharedModelContainer: ModelContainer = {
        // Recipe catalog (seeded from recipes.json) is the only SwiftData store.
        // All user-specific data (inventory, shopping list, cooking history,
        // pantry, profile) lives in Firestore.
        let schema = Schema([
            Recipe.self,
            RecipeIngredient.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .task {
                    await MainActor.run {
                        RecipeSeedService.seedIfNeeded(
                            modelContext: sharedModelContainer.mainContext
                        )
                    }
                    await NotificationService.shared.requestPermission()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification)
                ) { _ in
                    NotificationService.shared.resetBadge()
                    CookingSessionManager.shared.appDidForeground()
                }
                .onReceive(NotificationCenter.default.publisher(
                    for: UIApplication.didEnterBackgroundNotification)
                ) { _ in
                    CookingSessionManager.shared.appDidBackground()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}
