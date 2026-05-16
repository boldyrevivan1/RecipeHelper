//
//  FNSReceiptService.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 15.03.2026.
//

import Foundation

// MARK: - Models

struct FNSReceiptData: Codable {
    let date: String
    let operationType: Int
    let sum: Int
    let fsId: String
    let documentId: Int
    let fiscalSign: String
    
    enum CodingKeys: String, CodingKey {
        case date = "t"
        case operationType = "operationType"
        case sum = "s"
        case fsId = "fn"
        case documentId = "i"
        case fiscalSign = "fp"
    }
}

struct FNSReceipt: Codable {
    let document: FNSDocument
}

struct FNSDocument: Codable {
    let receipt: FNSReceiptDetails
}

struct FNSReceiptDetails: Codable {
    let dateTime: String
    let totalSum: Int
    let items: [FNSReceiptItem]
    let user: String?
    let retailPlaceAddress: String?
}

struct FNSReceiptItem: Codable {
    let name: String
    let price: Int
    let quantity: Double
    let sum: Int
}

// MARK: - Matched Product

struct MatchedProduct {
    let originalName: String
    let matchedIngredient: String
    let confidence: MatchConfidence
    let price: Int
    let quantity: Double
}

enum MatchConfidence {
    case exact      // 100% - точное совпадение
    case high       // 80-99% - частичное совпадение
    case medium     // 50-79% - похожее слово
    case low        // <50% - возможное совпадение
}

// MARK: - Service

class FNSReceiptService {
    
    static let shared = FNSReceiptService()
    
    private init() {}
    
    // MARK: - QR Parsing
    
    /// Парсинг данных из QR-кода чека
    func parseQRCode(_ qrString: String) -> FNSReceiptData? {
        print("==================================================")
        print("🔍 RAW QR CODE SCANNED:")
        print(qrString)
        print("==================================================")
        print("QR Length: \(qrString.count) characters")
        
        // Проверяем разные форматы
        
        // Формат 1: Стандартный ФНС (t=...&s=...&fn=...)
        if qrString.contains("t=") && qrString.contains("fn=") {
            print("✅ Detected FNS format")
            return parseFNSFormat(qrString)
        }
        
        // Формат 2: URL формат (https://...)
        if qrString.starts(with: "http") {
            print("✅ Detected URL format")
            return parseURLFormat(qrString)
        }
        
        // Формат 3: JSON формат
        if qrString.starts(with: "{") {
            print("✅ Detected JSON format")
            return parseJSONFormat(qrString)
        }
        
        print("❌ Unknown QR format")
        print("QR starts with: \(String(qrString.prefix(50)))")
        return nil
    }
    
    // MARK: - Format Parsers
    
    private func parseFNSFormat(_ qrString: String) -> FNSReceiptData? {
        var components: [String: String] = [:]
        
        let pairs = qrString.split(separator: "&")
        for pair in pairs {
            let keyValue = pair.split(separator: "=")
            if keyValue.count == 2 {
                components[String(keyValue[0])] = String(keyValue[1])
            }
        }
        
        guard let dateStr = components["t"],
              let sumStr = components["s"],
              let fsId = components["fn"],
              let docIdStr = components["i"],
              let fiscalSignStr = components["fp"],
              let opTypeStr = components["n"] else {
            print("❌ Missing required FNS parameters")
            return nil
        }
        
        // Парсим сумму (может быть с десятичной точкой в рублях)
        let sumDouble = Double(sumStr) ?? 0
        let sum = Int(sumDouble * 100) // Конвертируем рубли в копейки
        
        // Парсим остальные параметры
        let documentId = Int(docIdStr) ?? 0
        let operationType = Int(opTypeStr) ?? 1
        
        if sum == 0 {
            print("❌ Invalid sum value: \(sumStr)")
            return nil
        }
        
        print("✅ Successfully parsed FNS format")
        print("   Sum: \(sumStr) руб = \(sum) коп")
        print("   Date: \(dateStr)")
        print("   FN: \(fsId)")
        print("   Document ID: \(documentId)")
        
        return FNSReceiptData(
            date: dateStr,
            operationType: operationType,
            sum: sum,
            fsId: fsId,
            documentId: documentId,
            fiscalSign: String(fiscalSignStr)
        )
    }
    
    private func parseURLFormat(_ qrString: String) -> FNSReceiptData? {
        // Формат: https://check.ofd.ru/rec/123456...
        // Извлекаем параметры из URL
        
        guard let url = URL(string: qrString),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Failed to parse URL")
            return nil
        }
        
        print("URL Host: \(url.host ?? "none")")
        print("URL Path: \(url.path)")
        print("Query items: \(components.queryItems?.count ?? 0)")
        
        // Извлекаем параметры из query
        var params: [String: String] = [:]
        components.queryItems?.forEach { item in
            params[item.name] = item.value
        }
        
        // Пытаемся найти нужные параметры
        if let dateStr = params["t"],
           let sumStr = params["s"],
           let fsId = params["fn"] {
            
            let sumDouble = Double(sumStr) ?? 0
            let sum = Int(sumDouble * 100)
            let documentId = Int(params["i"] ?? "0") ?? 0
            let operationType = Int(params["n"] ?? "1") ?? 1
            
            return FNSReceiptData(
                date: dateStr,
                operationType: operationType,
                sum: sum,
                fsId: fsId,
                documentId: documentId,
                fiscalSign: params["fp"] ?? "0"
            )
        }
        
        print("❌ URL format missing required parameters")
        return nil
    }
    
    private func parseJSONFormat(_ qrString: String) -> FNSReceiptData? {
        // Если QR содержит JSON
        guard let data = qrString.data(using: .utf8) else {
            print("❌ Failed to convert JSON string to data")
            return nil
        }
        
        do {
            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("JSON keys: \(json.keys)")
                // Парсим JSON и ищем нужные поля
            }
        } catch {
            print("❌ JSON parsing failed: \(error)")
        }
        
        return nil
    }
    
    // MARK: - API Mock (для демо)
    
    /// Получение данных чека из API ФНС
    /// NOTE: В production здесь должен быть настоящий API запрос к ФНС
    /// Сейчас используем mock данные для демонстрации функционала
    func fetchReceipt(data: FNSReceiptData) async throws -> FNSReceipt {
        print("📡 Fetching receipt data...")
        
        // Симулируем задержку сети
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 секунда
        
        // Mock данные для демонстрации
        let mockReceipt = FNSReceipt(
            document: FNSDocument(
                receipt: FNSReceiptDetails(
                    dateTime: data.date,
                    totalSum: data.sum,
                    items: [
                        FNSReceiptItem(name: "Молоко 3.2% 1л", price: 89, quantity: 1.0, sum: 89),
                        FNSReceiptItem(name: "Хлеб Бородинский", price: 45, quantity: 1.0, sum: 45),
                        FNSReceiptItem(name: "Яйца С1 10шт", price: 120, quantity: 1.0, sum: 120),
                        FNSReceiptItem(name: "Помидоры свежие 1кг", price: 250, quantity: 0.5, sum: 125),
                        FNSReceiptItem(name: "Курица охлажденная 1кг", price: 280, quantity: 1.2, sum: 336),
                        FNSReceiptItem(name: "Сыр Российский 45%", price: 180, quantity: 0.3, sum: 54),
                        FNSReceiptItem(name: "Огурцы свежие 1кг", price: 200, quantity: 0.6, sum: 120),
                        FNSReceiptItem(name: "Масло подсолнечное 1л", price: 150, quantity: 1.0, sum: 150),
                        FNSReceiptItem(name: "Рис круглозерный 1кг", price: 95, quantity: 1.0, sum: 95),
                        FNSReceiptItem(name: "Макароны спагетти 500г", price: 70, quantity: 2.0, sum: 140),
                        FNSReceiptItem(name: "Лук репчатый 1кг", price: 40, quantity: 0.8, sum: 32),
                        FNSReceiptItem(name: "Морковь свежая 1кг", price: 50, quantity: 0.7, sum: 35),
                        FNSReceiptItem(name: "Картофель 1кг", price: 35, quantity: 2.0, sum: 70)
                    ],
                    user: "Продуктовый магазин",
                    retailPlaceAddress: "г. Москва"
                )
            )
        )
        
        print("✅ Receipt fetched: \(mockReceipt.document.receipt.items.count) items")
        
        return mockReceipt
    }
    
    // MARK: - Product Matching
    
    /// Сопоставление товаров из чека с известными ингредиентами
    func matchProducts(receiptItems: [FNSReceiptItem]) -> [MatchedProduct] {
        print("🔄 Matching \(receiptItems.count) receipt items with known ingredients...")
        print("📚 Available ingredients: \(KnownIngredients.all.count)")
        
        var matchedProducts: [MatchedProduct] = []
        
        for item in receiptItems {
            print("\n🔍 Trying to match: '\(item.name)'")
            if let match = findBestMatch(for: item) {
                matchedProducts.append(match)
                print("✅ MATCHED: '\(item.name)' → '\(match.matchedIngredient)' (confidence: \(match.confidence))")
            } else {
                print("❌ NO MATCH for: '\(item.name)'")
            }
        }
        
        print("\n📊 ========== MATCHING SUMMARY ==========")
        print("Total items in receipt: \(receiptItems.count)")
        print("Total matched products: \(matchedProducts.count)")
        print("==========================================\n")
        
        return matchedProducts
    }
    
    private func findBestMatch(for item: FNSReceiptItem) -> MatchedProduct? {
        let itemName = item.name.lowercased()
        
        // Словарь русских названий → английские из KnownIngredients
        let russianToEnglish: [String: String] = [
            "молоко": "Milk",
            "хлеб": "Bread",
            "яйца": "Eggs",
            "яйцо": "Eggs",
            "помидоры": "Tomatoes",
            "помидор": "Tomato",
            "курица": "Chicken",
            "куриц": "Chicken",
            "сыр": "Cheese",
            "огурцы": "Cucumber",
            "огурец": "Cucumber",
            "масло": "Oil",
            "подсолнечное": "Sunflower Oil",
            "оливковое": "Olive Oil",
            "рис": "Rice",
            "макароны": "Pasta",
            "спагетти": "Spaghetti",
            "лук": "Onion",
            "репчатый": "Onion",
            "морковь": "Carrot",
            "картофель": "Potato",
            "картошка": "Potato"
        ]
        
        // Ищем по русским словам
        for (russian, english) in russianToEnglish {
            if itemName.contains(russian) {
                print("  → Found Russian word '\(russian)' → '\(english)'")
                return MatchedProduct(
                    originalName: item.name,
                    matchedIngredient: english,
                    confidence: .exact,
                    price: item.price,
                    quantity: item.quantity
                )
            }
        }
        
        // Если не нашли в словаре, пробуем сопоставить с английскими названиями
        for ingredient in KnownIngredients.all {
            let ingredientLower = ingredient.lowercased()
            
            // Точное совпадение
            if itemName.contains(ingredientLower) {
                print("  → Exact match with '\(ingredient)'")
                return MatchedProduct(
                    originalName: item.name,
                    matchedIngredient: ingredient,
                    confidence: .exact,
                    price: item.price,
                    quantity: item.quantity
                )
            }
        }
        
        print("  → No match found in dictionary or KnownIngredients")
        return nil
    }
}

// MARK: - Error

enum FNSError: Error, LocalizedError {
    case invalidQRCode
    case networkError
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidQRCode:
            return "Invalid QR code format"
        case .networkError:
            return "Network error while fetching receipt"
        case .parsingError:
            return "Failed to parse receipt data"
        }
    }
}
