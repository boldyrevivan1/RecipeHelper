//
//  IngredientMatcher.swift
//  RecipeHelper
//

import Foundation

// MARK: - Match Result

struct IngredientMatch {
    let englishName:  String
    let category:     String
    let defaultDays:  Int      // дефолтный срок годности в днях
}

// MARK: - Matcher

enum IngredientMatcher {

    static func match(russianName name: String) -> IngredientMatch? {
        let lower = name.lowercased()
        for (key, value) in entries.sorted(by: { $0.key.count > $1.key.count }) {
            if lower.contains(key) { return value }
        }
        return nil
    }

    /// Reverse lookup: find a match whose `englishName` equals the given
    /// English ingredient name (case-insensitive). Used by the shopping list
    /// to auto-fill category & expiration when moving items into inventory.
    static func match(englishName name: String) -> IngredientMatch? {
        let lower = name.lowercased().trimmingCharacters(in: .whitespaces)
        return entries.values.first { $0.englishName.lowercased() == lower }
    }

    // MARK: - Dictionary

    static let entries: [String: IngredientMatch] = {
        func m(_ name: String, _ cat: String, _ days: Int) -> IngredientMatch {
            IngredientMatch(englishName: name, category: cat, defaultDays: days)
        }

        return [
            // Dairy (7-14 days)
            "молоко":       m("Milk",           "Dairy",   7),
            "молок":        m("Milk",           "Dairy",   7),
            "кефир":        m("Kefir",          "Dairy",   7),
            "ряженка":      m("Ryazhenka",      "Dairy",   7),
            "йогурт":       m("Yogurt",         "Dairy",   10),
            "сметана":      m("Sour Cream",     "Dairy",   10),
            "сливки":       m("Cream",          "Dairy",   7),
            "творог":       m("Cottage Cheese", "Dairy",   5),
            "масло слив":   m("Butter",         "Dairy",   30),
            "масло слоч":   m("Butter",         "Dairy",   30),
            "сыр":          m("Cheese",         "Dairy",   14),

            // Eggs (21 days)
            "яйц":          m("Eggs",           "Dairy",   21),
            "яйко":         m("Eggs",           "Dairy",   21),

            // Meat (3-5 days fresh)
            "курица":       m("Chicken",        "Meat",    3),
            "куриц":        m("Chicken",        "Meat",    3),
            "куриная":      m("Chicken Breast", "Meat",    3),
            "куриное":      m("Chicken",        "Meat",    3),
            "грудка":       m("Chicken Breast", "Meat",    3),
            "бедро":        m("Chicken Thigh",  "Meat",    3),
            "голень":       m("Chicken Drumstick","Meat",  3),
            "говядина":     m("Beef",           "Meat",    4),
            "говяд":        m("Beef",           "Meat",    4),
            "фарш говяж":   m("Ground Beef",    "Meat",    2),
            "фарш":         m("Minced Meat",    "Meat",    2),
            "свинина":      m("Pork",           "Meat",    4),
            "свин":         m("Pork",           "Meat",    4),
            "бекон":        m("Bacon",          "Meat",    7),
            "сосиск":       m("Sausage",        "Meat",    5),
            "колбас":       m("Sausage",        "Meat",    5),
            "ветчина":      m("Ham",            "Meat",    7),
            "баранина":     m("Lamb",           "Meat",    4),
            "индейка":      m("Turkey",         "Meat",    3),
            "утка":         m("Duck",           "Meat",    3),

            // Seafood (2 days fresh)
            "лосось":       m("Salmon",         "Seafood", 2),
            "семга":        m("Salmon",         "Seafood", 2),
            "тунец":        m("Tuna",           "Seafood", 2),
            "треска":       m("Cod",            "Seafood", 2),
            "креветк":      m("Shrimp",         "Seafood", 2),
            "краб":         m("Crab",           "Seafood", 2),
            "мидии":        m("Mussels",        "Seafood", 2),
            "кальмар":      m("Squid",          "Seafood", 2),
            "сельдь":       m("Herring",        "Seafood", 3),
            "скумбрия":     m("Mackerel",       "Seafood", 3),
            "рыба":         m("Fish",           "Seafood", 2),

            // Vegetables (5-14 days)
            "томат":        m("Tomatoes",       "Vegetables", 7),
            "помидор":      m("Tomatoes",       "Vegetables", 7),
            "лук репч":     m("Onion",          "Vegetables", 30),
            "лук зел":      m("Green Onion",    "Vegetables", 7),
            "лук":          m("Onion",          "Vegetables", 30),
            "чеснок":       m("Garlic",         "Vegetables", 30),
            "картофель":    m("Potato",         "Vegetables", 60),
            "картошка":     m("Potato",         "Vegetables", 60),
            "морковь":      m("Carrots",        "Vegetables", 21),
            "морков":       m("Carrots",        "Vegetables", 21),
            "перец болг":   m("Bell Pepper",    "Vegetables", 10),
            "перец слад":   m("Bell Pepper",    "Vegetables", 10),
            "огурец":       m("Cucumber",       "Vegetables", 7),
            "огурц":        m("Cucumber",       "Vegetables", 7),
            "салат":        m("Lettuce",        "Vegetables", 5),
            "шпинат":       m("Spinach",        "Vegetables", 5),
            "брокколи":     m("Broccoli",       "Vegetables", 7),
            "цветная кап":  m("Cauliflower",    "Vegetables", 7),
            "капуста":      m("Cabbage",        "Vegetables", 14),
            "кабачок":      m("Zucchini",       "Vegetables", 10),
            "баклажан":     m("Eggplant",       "Vegetables", 10),
            "сельдерей":    m("Celery",         "Vegetables", 14),
            "гриб":         m("Mushrooms",      "Vegetables", 5),
            "шампиньон":    m("Mushrooms",      "Vegetables", 5),
            "вешенк":       m("Oyster Mushrooms","Vegetables",5),
            "горошек":      m("Peas",           "Vegetables", 5),
            "кукуруза":     m("Corn",           "Vegetables", 5),
            "свекла":       m("Beets",          "Vegetables", 30),
            "редис":        m("Radish",         "Vegetables", 7),

            // Fruits (5-14 days)
            "яблок":        m("Apples",         "Fruits", 21),
            "банан":        m("Bananas",        "Fruits", 7),
            "апельсин":     m("Oranges",        "Fruits", 14),
            "лимон":        m("Lemons",         "Fruits", 21),
            "лайм":         m("Limes",          "Fruits", 14),
            "клубник":      m("Strawberries",   "Fruits", 3),
            "черника":      m("Blueberries",    "Fruits", 5),
            "виноград":     m("Grapes",         "Fruits", 7),
            "арбуз":        m("Watermelon",     "Fruits", 7),
            "ананас":       m("Pineapple",      "Fruits", 5),
            "манго":        m("Mango",          "Fruits", 5),
            "персик":       m("Peach",          "Fruits", 5),
            "груша":        m("Pear",           "Fruits", 7),
            "черешня":      m("Cherries",       "Fruits", 5),
            "вишня":        m("Cherries",       "Fruits", 5),
            "авокадо":      m("Avocado",        "Fruits", 5),

            // Grains & Pasta (180-365 days)
            "рис":          m("Rice",           "Grains", 365),
            "макарон":      m("Pasta",          "Grains", 365),
            "спагетти":     m("Spaghetti",      "Grains", 365),
            "лапша":        m("Noodles",        "Grains", 365),
            "вермишель":    m("Noodles",        "Grains", 365),
            "гречка":       m("Buckwheat",      "Grains", 365),
            "гречнев":      m("Buckwheat",      "Grains", 365),
            "овсянка":      m("Oats",           "Grains", 180),
            "геркулес":     m("Oats",           "Grains", 180),
            "перловка":     m("Pearl Barley",   "Grains", 365),
            "пшено":        m("Millet",         "Grains", 365),
            "мука":         m("Flour",          "Grains", 180),
            "хлеб":         m("Bread",          "Bakery", 5),

            // Oils & Sauces (60-365 days)
            "масло олив":   m("Olive Oil",      "Oils",   365),
            "масло подсол": m("Sunflower Oil",  "Oils",   365),
            "масло растит": m("Vegetable Oil",  "Oils",   365),
            "масло":        m("Cooking Oil",    "Oils",   365),
            "кетчуп":       m("Ketchup",        "Sauces", 60),
            "майонез":      m("Mayonnaise",     "Sauces", 60),
            "горчица":      m("Mustard",        "Sauces", 60),
            "соевый соус":  m("Soy Sauce",      "Sauces", 180),
            "уксус":        m("Vinegar",        "Sauces", 365),

            // Spices (365 days)
            "соль":         m("Salt",           "Spices", 1825),
            "перец черн":   m("Black Pepper",   "Spices", 365),
            "паприка":      m("Paprika",        "Spices", 365),
            "куркума":      m("Turmeric",       "Spices", 365),
            "корица":       m("Cinnamon",       "Spices", 365),
            "имбирь":       m("Ginger",         "Spices", 365),
            "укроп":        m("Dill",           "Spices", 365),
            "петрушка":     m("Parsley",        "Vegetables", 7),
            "базилик":      m("Basil",          "Vegetables", 7),

            // Baking (90-365 days)
            "сахар":        m("Sugar",          "Baking", 730),
            "мед":          m("Honey",          "Baking", 730),
            "шоколад":      m("Chocolate",      "Baking", 180),
            "какао":        m("Cocoa Powder",   "Baking", 365),
            "разрыхлит":    m("Baking Powder",  "Baking", 365),
            "сода пищев":   m("Baking Soda",    "Baking", 365),

            // Nuts (90-180 days)
            "миндаль":      m("Almonds",        "Nuts", 180),
            "грецкий орех": m("Walnuts",        "Nuts", 90),
            "орех":         m("Walnuts",        "Nuts", 90),
            "кешью":        m("Cashews",        "Nuts", 180),
            "арахис":       m("Peanuts",        "Nuts", 180),
            "фисташк":      m("Pistachios",     "Nuts", 180),
            "фундук":       m("Hazelnuts",      "Nuts", 180),

            // Legumes (365 days)
            "нут":          m("Chickpeas",      "Legumes", 365),
            "чечевица":     m("Lentils",        "Legumes", 365),
            "горох":        m("Peas",           "Legumes", 365),
            "фасоль":       m("Beans",          "Legumes", 365),

            // Other
            "тофу":         m("Tofu",           "Legumes", 7),
            "бульон":       m("Stock",          "Other", 3),

            // ==== English aliases — for reverse lookup & shopping list auto-match ====
            // Keys must be lowercase. Longer, more specific keys win (sorted by length).

            // Cheeses (specific types → Dairy)
            "cheddar":         m("Cheddar",        "Dairy", 21),
            "mozzarella":      m("Mozzarella",     "Dairy", 10),
            "parmesan":        m("Parmesan",       "Dairy", 60),
            "pecorino":        m("Pecorino",       "Dairy", 60),
            "feta":            m("Feta",           "Dairy", 14),
            "ricotta":         m("Ricotta",        "Dairy", 7),
            "cream cheese":    m("Cream Cheese",   "Dairy", 21),
            "cottage cheese":  m("Cottage Cheese", "Dairy", 5),
            "sour cream":      m("Sour Cream",     "Dairy", 10),

            // Butter variants (fat → Dairy, nut butters → Nuts)
            "peanut butter":   m("Peanut Butter",  "Nuts",  180),
            "almond butter":   m("Almond Butter",  "Nuts",  180),
            "butter":          m("Butter",         "Dairy", 30),

            // Eggs category (separate from Dairy in grocery reality,
            // но у нас категории Eggs нет, оставляем Dairy)
            "eggs":            m("Eggs",           "Dairy", 21),
            "egg":             m("Eggs",           "Dairy", 21),

            // Meat aliases
            "ground beef":     m("Ground Beef",    "Meat", 2),
            "minced meat":     m("Minced Meat",    "Meat", 2),
            "chicken breast":  m("Chicken Breast", "Meat", 3),
            "chicken thigh":   m("Chicken Thigh",  "Meat", 3),
            "chicken drumstick":m("Chicken Drumstick","Meat", 3),
            "bacon":           m("Bacon",          "Meat", 7),
            "pancetta":        m("Pancetta",       "Meat", 14),
            "ham":             m("Ham",            "Meat", 7),
            "sausage":         m("Sausage",        "Meat", 5),
            "chicken":         m("Chicken",        "Meat", 3),
            "beef":            m("Beef",           "Meat", 4),
            "pork":            m("Pork",           "Meat", 4),
            "lamb":             m("Lamb",          "Meat", 4),
            "turkey":          m("Turkey",         "Meat", 3),
            "duck":            m("Duck",           "Meat", 3),

            // Seafood aliases
            "salmon":          m("Salmon",         "Seafood", 2),
            "tuna":            m("Tuna",           "Seafood", 2),
            "cod":             m("Cod",            "Seafood", 2),
            "shrimp":          m("Shrimp",         "Seafood", 2),
            "crab":            m("Crab",           "Seafood", 2),
            "mussels":         m("Mussels",        "Seafood", 2),
            "squid":           m("Squid",          "Seafood", 2),
            "herring":         m("Herring",        "Seafood", 3),
            "mackerel":        m("Mackerel",       "Seafood", 3),
            "fish":            m("Fish",           "Seafood", 2),

            // Vegetables & herbs (herbs → Vegetables if fresh, Spices if dried)
            "bell pepper":     m("Bell Pepper",    "Vegetables", 10),
            "green onion":     m("Green Onion",    "Vegetables", 7),
            "oyster mushrooms":m("Oyster Mushrooms","Vegetables", 5),
            "mushrooms":       m("Mushrooms",      "Vegetables", 5),
            "cauliflower":     m("Cauliflower",    "Vegetables", 7),
            "cabbage":         m("Cabbage",        "Vegetables", 14),
            "eggplant":        m("Eggplant",       "Vegetables", 10),
            "zucchini":        m("Zucchini",       "Vegetables", 10),
            "tomatoes":        m("Tomatoes",       "Vegetables", 7),
            "tomato":          m("Tomatoes",       "Vegetables", 7),
            "cucumber":        m("Cucumber",       "Vegetables", 7),
            "carrots":         m("Carrots",        "Vegetables", 21),
            "spinach":         m("Spinach",        "Vegetables", 5),
            "lettuce":         m("Lettuce",        "Vegetables", 5),
            "potato":          m("Potato",         "Vegetables", 60),
            "potatoes":        m("Potato",         "Vegetables", 60),
            "onion":           m("Onion",          "Vegetables", 30),
            "garlic":          m("Garlic",         "Vegetables", 30),
            "ginger":          m("Ginger",         "Vegetables", 30),
            "celery":          m("Celery",         "Vegetables", 14),
            "beets":           m("Beets",          "Vegetables", 30),
            "corn":            m("Corn",           "Vegetables", 5),
            "radish":          m("Radish",         "Vegetables", 7),
            "peas":            m("Peas",           "Vegetables", 5),
            "green beans":     m("Green Beans",    "Vegetables", 7),
            "parsley":         m("Parsley",        "Vegetables", 7),
            "basil":           m("Basil",          "Vegetables", 7),
            "dill":            m("Dill",           "Vegetables", 7),
            "cilantro":        m("Cilantro",       "Vegetables", 7),

            // Fruits
            "apples":          m("Apples",         "Fruits", 21),
            "bananas":          m("Bananas",       "Fruits", 7),
            "oranges":         m("Oranges",        "Fruits", 14),
            "lemons":          m("Lemons",         "Fruits", 21),
            "lemon":           m("Lemons",         "Fruits", 21),
            "limes":           m("Limes",          "Fruits", 14),
            "lime":            m("Limes",          "Fruits", 14),
            "strawberries":    m("Strawberries",   "Fruits", 3),
            "blueberries":     m("Blueberries",    "Fruits", 5),
            "cherries":        m("Cherries",       "Fruits", 5),
            "grapes":          m("Grapes",         "Fruits", 7),
            "mango":           m("Mango",          "Fruits", 5),
            "pineapple":       m("Pineapple",      "Fruits", 5),
            "peach":           m("Peach",          "Fruits", 5),
            "pear":            m("Pear",           "Fruits", 7),
            "watermelon":      m("Watermelon",     "Fruits", 7),
            "avocado":         m("Avocado",        "Fruits", 5),

            // Grains & pasta
            "basmati rice":    m("Basmati Rice",   "Grains", 365),
            "rice":            m("Rice",           "Grains", 365),
            "pasta":           m("Pasta",          "Grains", 365),
            "spaghetti":       m("Spaghetti",      "Grains", 365),
            "noodles":         m("Noodles",        "Grains", 365),
            "flour":           m("Flour",          "Grains", 180),
            "oats":            m("Oats",           "Grains", 180),
            "buckwheat":       m("Buckwheat",      "Grains", 365),
            "millet":          m("Millet",         "Grains", 365),
            "pearl barley":    m("Pearl Barley",   "Grains", 365),
            "bread":           m("Bread",          "Bakery", 5),

            // Legumes
            "black beans":     m("Black Beans",    "Legumes", 365),
            "kidney beans":    m("Kidney Beans",   "Legumes", 365),
            "red lentils":     m("Red Lentils",    "Legumes", 365),
            "lentils":         m("Lentils",        "Legumes", 365),
            "chickpeas":       m("Chickpeas",      "Legumes", 365),
            "beans":           m("Beans",          "Legumes", 365),
            "tofu":            m("Tofu",           "Legumes", 7),

            // Oils (fats → Oils)
            "olive oil":       m("Olive Oil",      "Oils", 365),
            "coconut oil":     m("Coconut Oil",    "Oils", 365),
            "sesame oil":      m("Sesame Oil",     "Oils", 365),
            "sunflower oil":   m("Sunflower Oil",  "Oils", 365),
            "vegetable oil":   m("Vegetable Oil",  "Oils", 365),
            "cooking oil":     m("Cooking Oil",    "Oils", 365),

            // Sauces / condiments
            "tomato sauce":    m("Tomato Sauce",   "Sauces", 30),
            "bbq sauce":       m("BBQ Sauce",      "Sauces", 180),
            "soy sauce":       m("Soy Sauce",      "Sauces", 180),
            "mayonnaise":      m("Mayonnaise",     "Sauces", 60),
            "ketchup":         m("Ketchup",        "Sauces", 60),
            "mustard":         m("Mustard",        "Sauces", 60),
            "vinegar":         m("Vinegar",        "Sauces", 365),
            "red wine":        m("Red Wine",       "Sauces", 30),     // cooking wine
            "white wine":      m("White Wine",     "Sauces", 30),

            // Stocks (broths)
            "chicken stock":   m("Chicken Stock",  "Sauces", 7),
            "beef stock":      m("Beef Stock",     "Sauces", 7),
            "vegetable stock": m("Vegetable Stock","Sauces", 7),
            "stock":           m("Stock",          "Sauces", 7),

            // Spices (dried herbs & powders)
            "black pepper":    m("Black Pepper",   "Spices", 365),
            "paprika":         m("Paprika",        "Spices", 365),
            "cumin":           m("Cumin",          "Spices", 365),
            "coriander":       m("Coriander",      "Spices", 365),
            "oregano":         m("Oregano",        "Spices", 365),
            "rosemary":        m("Rosemary",       "Spices", 365),
            "turmeric":        m("Turmeric",       "Spices", 365),
            "cinnamon":        m("Cinnamon",       "Spices", 365),
            "salt":            m("Salt",           "Spices", 1825),

            // Nuts
            "pine nuts":       m("Pine Nuts",      "Nuts", 90),
            "walnuts":         m("Walnuts",        "Nuts", 90),
            "almonds":         m("Almonds",        "Nuts", 180),
            "cashews":         m("Cashews",        "Nuts", 180),
            "peanuts":         m("Peanuts",        "Nuts", 180),
            "pistachios":      m("Pistachios",     "Nuts", 180),
            "hazelnuts":       m("Hazelnuts",      "Nuts", 180),

            // Baking
            "baking powder":   m("Baking Powder",  "Baking", 365),
            "baking soda":     m("Baking Soda",    "Baking", 365),
            "cocoa powder":    m("Cocoa Powder",   "Baking", 365),
            "chocolate":       m("Chocolate",      "Baking", 180),
            "sugar":           m("Sugar",          "Baking", 730),
            "honey":           m("Honey",          "Baking", 730),

            // Dairy (generic names, also reachable via russian keys)
            "milk":            m("Milk",           "Dairy", 7),
            "cream":           m("Cream",          "Dairy", 7),
            "yogurt":          m("Yogurt",         "Dairy", 10),
            "kefir":           m("Kefir",          "Dairy", 7),
            "cheese":          m("Cheese",         "Dairy", 14),
        ]
    }()
}
