//
//  MealDBService.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 30.01.2026.
//

import Foundation

// MARK: - API Models
struct MealDBResponse: Codable {
    let meals: [MealDTO]?
}

struct MealDTO: Codable {
    let idMeal: String
    let strMeal: String
    let strCategory: String?
    let strArea: String?
    let strInstructions: String?
    let strMealThumb: String?
    let strTags: String?
    
    // Ингредиенты (до 20 возможных)
    let strIngredient1: String?
    let strIngredient2: String?
    let strIngredient3: String?
    let strIngredient4: String?
    let strIngredient5: String?
    let strIngredient6: String?
    let strIngredient7: String?
    let strIngredient8: String?
    let strIngredient9: String?
    let strIngredient10: String?
    let strIngredient11: String?
    let strIngredient12: String?
    let strIngredient13: String?
    let strIngredient14: String?
    let strIngredient15: String?
    let strIngredient16: String?
    let strIngredient17: String?
    let strIngredient18: String?
    let strIngredient19: String?
    let strIngredient20: String?
    
    // Меры (до 20 возможных)
    let strMeasure1: String?
    let strMeasure2: String?
    let strMeasure3: String?
    let strMeasure4: String?
    let strMeasure5: String?
    let strMeasure6: String?
    let strMeasure7: String?
    let strMeasure8: String?
    let strMeasure9: String?
    let strMeasure10: String?
    let strMeasure11: String?
    let strMeasure12: String?
    let strMeasure13: String?
    let strMeasure14: String?
    let strMeasure15: String?
    let strMeasure16: String?
    let strMeasure17: String?
    let strMeasure18: String?
    let strMeasure19: String?
    let strMeasure20: String?
    
    // Вспомогательный метод для извлечения ингредиентов
    func getIngredients() -> [(ingredient: String, measure: String)] {
        var ingredients: [(String, String)] = []
        
        let ingredientsList = [
            strIngredient1, strIngredient2, strIngredient3, strIngredient4, strIngredient5,
            strIngredient6, strIngredient7, strIngredient8, strIngredient9, strIngredient10,
            strIngredient11, strIngredient12, strIngredient13, strIngredient14, strIngredient15,
            strIngredient16, strIngredient17, strIngredient18, strIngredient19, strIngredient20
        ]
        
        let measuresList = [
            strMeasure1, strMeasure2, strMeasure3, strMeasure4, strMeasure5,
            strMeasure6, strMeasure7, strMeasure8, strMeasure9, strMeasure10,
            strMeasure11, strMeasure12, strMeasure13, strMeasure14, strMeasure15,
            strMeasure16, strMeasure17, strMeasure18, strMeasure19, strMeasure20
        ]
        
        for i in 0..<ingredientsList.count {
            if let ingredient = ingredientsList[i],
               let measure = measuresList[i],
               !ingredient.trimmingCharacters(in: .whitespaces).isEmpty,
               !measure.trimmingCharacters(in: .whitespaces).isEmpty {
                ingredients.append((ingredient.trimmingCharacters(in: .whitespaces),
                                  measure.trimmingCharacters(in: .whitespaces)))
            }
        }
        
        return ingredients
    }
}

// MARK: - Service
class MealDBService {
    static let shared = MealDBService()
    
    private let baseURL = "https://www.themealdb.com/api/json/v1/1"
    
    private init() {}
    
    // Поиск рецептов по названию
    func searchMeals(query: String) async throws -> [MealDTO] {
        let urlString = "\(baseURL)/search.php?s=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MealDBResponse.self, from: data)
        
        return result.meals ?? []
    }
    
    // Получить случайный рецепт
    func getRandomMeal() async throws -> MealDTO? {
        let urlString = "\(baseURL)/random.php"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MealDBResponse.self, from: data)
        
        return result.meals?.first
    }
    
    // Получить рецепт по ID
    func getMealDetails(id: String) async throws -> MealDTO? {
        let urlString = "\(baseURL)/lookup.php?i=\(id)"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MealDBResponse.self, from: data)
        
        return result.meals?.first
    }
    
    // Получить рецепты по категории
    func getMealsByCategory(category: String) async throws -> [MealDTO] {
        let urlString = "\(baseURL)/filter.php?c=\(category.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MealDBResponse.self, from: data)
        
        return result.meals ?? []
    }
    
    // Получить рецепты по основному ингредиенту
    func getMealsByIngredient(ingredient: String) async throws -> [MealDTO] {
        let urlString = "\(baseURL)/filter.php?i=\(ingredient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let result = try decoder.decode(MealDBResponse.self, from: data)
        
        return result.meals ?? []
    }
}

// MARK: - Errors
enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Неверный URL"
        case .invalidResponse:
            return "Ошибка ответа сервера"
        case .decodingError:
            return "Ошибка декодирования данных"
        }
    }
}
