# RecipeHelper

A native iOS app for personal pantry management and recipe recommendations, built as a bachelor's thesis project at HSE Faculty of Computer Science (2026).

---

## Motivation

People living independently often throw away food that expired unnoticed, overbuy at the store, and end up ordering delivery instead of cooking. Existing apps either cover recipes or shopping lists, but none of them connects the two with a personal inventory. RecipeHelper puts all three in one place.

---

## How It Works

The core of the app is an ingredient matching engine. For each recipe it calculates what fraction of the required ingredients the user already has at home, ignoring pantry staples (salt, pepper, water, etc.) that are configured during onboarding. The home screen shows the best match; the recipes screen sorts the full catalogue by score. When a product is about to expire, the app sends a local notification.

---

## Features

**Inventory**
- Add products manually, by barcode scan, or by photographing a grocery receipt (OCR via Apple Vision)
- Track expiration dates with color-coded status
- Expiration notifications

**Recipes**
- 150 built-in recipes, fully available offline
- Sorted by how many ingredients you currently have
- Dietary preferences and allergen filters set once during onboarding

**Cooking**
- Step-by-step cooking session with a background-aware timer (keeps running when the screen locks)
- One-tap to subtract used ingredients from inventory after cooking
- Cooking history with statistics

**Shopping List**
- Auto-generated from missing ingredients for a chosen recipe
- One tap to move purchased items into inventory

**Account**
- Email/password auth with verification
- Onboarding: dietary preferences, allergens, pantry staples
- Profile with preferences editing

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Local storage | SwiftData (recipe catalogue) |
| Remote storage | Cloud Firestore |
| Auth | Firebase Authentication |
| OCR | Apple Vision framework |
| Recipe metadata | MealDB API |

**Why this stack:** The recipe catalogue ships with the app and works offline via SwiftData. User data (inventory, shopping list, history) syncs in real time through Firestore, including offline write queuing. Apple Vision handles receipt scanning without a third-party dependency.

---

## Architecture

The app follows a three-layer structure: data layer (SwiftData + Firestore), service layer (FirestoreService, AuthService, RecipeMatchService, CookingSessionManager, NotificationService), and view layer (SwiftUI). Views observe services via `@ObservedObject`; writes flow through services into Firestore, which triggers snapshot listeners that update the UI.

---

## Project Structure

```
RecipeHelper/
├── App/
│   └── RecipeHelperApp.swift        # entry point, Firebase setup
├── Models/
│   ├── Recipe.swift                 # SwiftData model for recipes and ingredients
│   └── Ingredient.swift             # ingredient data structure
├── Services/
│   ├── AuthService.swift            # Firebase Authentication wrapper
│   ├── CookingSessionManager.swift  # active cooking timers, survives tab navigation
│   ├── MealDBService.swift          # fetches extra recipe details from MealDB API
│   ├── NotificationService.swift    # local notifications for expiring products
│   ├── ReceiptOCRService.swift      # Apple Vision OCR for grocery receipts
│   ├── RecipeMatchService.swift     # match score calculation
│   ├── RecipeSeedService.swift      # seeds SwiftData store from bundled recipes.json
│   └── FNSReceiptService.swift      # receipt QR parsing
├── Utilities/
│   ├── IngredientMatcher.swift      # name normalization and synonym matching
│   ├── KnownIngredients.swift       # curated ingredient dictionary
│   ├── RecipeConverter.swift        # converts MealDB response to local model
│   ├── CachedAsyncImage.swift       # async image loading with cache
│   └── QuantityStatusStyle.swift    # shared UI helpers for quantity display
├── Views/
│   ├── RootView.swift               # auth gate, switches between auth and main app
│   ├── MainTabView.swift            # five-tab container
│   ├── DashboardView.swift          # home screen with best recipe match
│   ├── InventoryView.swift          # product list with expiration status
│   ├── AddProductView.swift         # manual product entry
│   ├── EditProductView.swift        # edit existing product
│   ├── RecipesView.swift            # full catalogue sorted by match score
│   ├── RecipeDetailView.swift       # recipe info and start cooking button
│   ├── FavoritesView.swift          # saved recipes
│   ├── CookingSessionView.swift     # step-by-step cooking with timer
│   ├── CookingBannerView.swift      # persistent banner when session is active
│   ├── CookingHistoryView.swift     # past cooking sessions and statistics
│   ├── ShoppingListView.swift       # missing ingredients list
│   ├── PantryView.swift             # staple ingredients always treated as available
│   ├── ProfileView.swift            # account info and preferences
│   ├── EditPreferencesView.swift    # edit dietary preferences and allergens
│   ├── OnboardingView.swift         # first-launch setup flow
│   ├── AuthView.swift               # sign in / sign up
│   ├── EmailVerificationView.swift  # email verification screen
│   ├── QRScannerView.swift          # barcode / QR scanner
│   ├── ContentView.swift            # root content wrapper
│   └── FirestoreService.swift       # Firestore listeners and write methods
└── Resources/
    ├── recipes.json                 # bundled recipe catalogue (150 recipes)
    └── Assets.xcassets/             # app icon and recipe images
```

---

## Requirements

- iOS 16+
- Xcode 15+
- Firebase project with `GoogleService-Info.plist`
