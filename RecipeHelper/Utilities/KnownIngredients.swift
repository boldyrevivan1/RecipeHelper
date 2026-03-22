//
//  KnownIngredients.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 15.03.2026.
//

import Foundation

struct KnownIngredients {
    
    // MARK: - Categories
    
    static let vegetables = [
        "Tomato", "Tomatoes", "Onion", "Onions", "Garlic", "Potato", "Potatoes",
        "Carrot", "Carrots", "Bell Pepper", "Cucumber", "Lettuce", "Spinach",
        "Broccoli", "Cauliflower", "Cabbage", "Zucchini", "Eggplant", "Celery",
        "Mushrooms", "Green Beans", "Peas", "Corn", "Asparagus", "Radish"
    ]
    
    static let fruits = [
        "Apple", "Apples", "Banana", "Bananas", "Orange", "Oranges", "Lemon",
        "Lemons", "Lime", "Limes", "Strawberry", "Strawberries", "Blueberries",
        "Grapes", "Watermelon", "Pineapple", "Mango", "Peach", "Pear", "Cherry",
        "Cherries", "Avocado", "Coconut", "Kiwi"
    ]
    
    static let meat = [
        "Chicken", "Chicken Breast", "Chicken Thigh", "Chicken Drumstick",
        "Beef", "Ground Beef", "Beef Steak", "Pork", "Pork Chops", "Bacon",
        "Sausage", "Ham", "Lamb", "Turkey", "Duck", "Minced Meat"
    ]
    
    static let seafood = [
        "Salmon", "Tuna", "Cod", "Shrimp", "Prawns", "Crab", "Lobster",
        "Mussels", "Clams", "Squid", "Octopus", "Tilapia", "Sardines",
        "Anchovies", "Mackerel"
    ]
    
    static let dairy = [
        "Milk", "Whole Milk", "Skim Milk", "Butter", "Cheese", "Cheddar",
        "Mozzarella", "Parmesan", "Cream", "Heavy Cream", "Sour Cream",
        "Yogurt", "Greek Yogurt", "Cream Cheese", "Cottage Cheese"
    ]
    
    static let grains = [
        "Rice", "White Rice", "Brown Rice", "Basmati Rice", "Pasta", "Spaghetti",
        "Penne", "Fusilli", "Macaroni", "Bread", "Flour", "All-Purpose Flour",
        "Whole Wheat Flour", "Oats", "Quinoa", "Couscous", "Noodles"
    ]
    
    static let spices = [
        "Salt", "Black Pepper", "Paprika", "Cumin", "Coriander", "Cinnamon",
        "Nutmeg", "Ginger", "Turmeric", "Chili Powder", "Cayenne Pepper",
        "Oregano", "Basil", "Thyme", "Rosemary", "Bay Leaf", "Parsley",
        "Mint", "Dill", "Sage", "Vanilla Extract"
    ]
    
    static let oils = [
        "Olive Oil", "Vegetable Oil", "Coconut Oil", "Sunflower Oil",
        "Sesame Oil", "Canola Oil", "Butter", "Cooking Oil"
    ]
    
    static let sauces = [
        "Soy Sauce", "Tomato Sauce", "Hot Sauce", "BBQ Sauce", "Ketchup",
        "Mustard", "Mayonnaise", "Vinegar", "Balsamic Vinegar", "Worcestershire Sauce",
        "Fish Sauce", "Oyster Sauce", "Teriyaki Sauce"
    ]
    
    static let bakingEssentials = [
        "Sugar", "Brown Sugar", "Powdered Sugar", "Honey", "Maple Syrup",
        "Baking Powder", "Baking Soda", "Yeast", "Cocoa Powder", "Chocolate",
        "Chocolate Chips", "Vanilla Extract"
    ]
    
    static let nuts = [
        "Almonds", "Walnuts", "Cashews", "Peanuts", "Pecans", "Pistachios",
        "Hazelnuts", "Pine Nuts", "Peanut Butter", "Almond Butter"
    ]
    
    static let beans = [
        "Black Beans", "Kidney Beans", "Chickpeas", "Lentils", "White Beans",
        "Pinto Beans", "Green Lentils", "Red Lentils"
    ]
    
    static let other = [
        "Eggs", "Tofu", "Tempeh", "Stock", "Chicken Stock", "Beef Stock",
        "Vegetable Stock", "Wine", "Red Wine", "White Wine", "Beer"
    ]
    
    // MARK: - All Ingredients
    
    static let all: [String] = {
        var allIngredients: [String] = []
        allIngredients.append(contentsOf: vegetables)
        allIngredients.append(contentsOf: fruits)
        allIngredients.append(contentsOf: meat)
        allIngredients.append(contentsOf: seafood)
        allIngredients.append(contentsOf: dairy)
        allIngredients.append(contentsOf: grains)
        allIngredients.append(contentsOf: spices)
        allIngredients.append(contentsOf: oils)
        allIngredients.append(contentsOf: sauces)
        allIngredients.append(contentsOf: bakingEssentials)
        allIngredients.append(contentsOf: nuts)
        allIngredients.append(contentsOf: beans)
        allIngredients.append(contentsOf: other)
        return allIngredients.sorted()
    }()
    
    // MARK: - Search Method
    
    /// Поиск ингредиентов по запросу
    static func search(query: String) -> [String] {
        guard !query.isEmpty else { return [] }
        
        let lowercasedQuery = query.lowercased()
        
        return all.filter { ingredient in
            ingredient.lowercased().contains(lowercasedQuery)
        }
    }
    
    /// Проверка существует ли ингредиент
    static func isValid(ingredient: String) -> Bool {
        return all.contains { $0.lowercased() == ingredient.lowercased() }
    }
}
