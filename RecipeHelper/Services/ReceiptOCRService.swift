import Vision
import UIKit

enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Не удалось загрузить изображение"
        case .noTextFound:  return "Текст на чеке не распознан — попробуйте другое фото"
        }
    }
}

struct ReceiptProduct: Identifiable {
    let id    = UUID()
    let name:  String
    let price: Double?
}

final class ReceiptOCRService: Sendable {

    static let shared = ReceiptOCRService()
    private init() {}

    func recognizeProducts(from image: UIImage) async throws -> [ReceiptProduct] {
        let text     = try await recognizeText(from: image)
        let products = extractProducts(from: text)
        guard !products.isEmpty else { throw OCRError.noTextFound }
        return products
    }

    private func recognizeText(from image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw OCRError.invalidImage }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel     = .accurate
            request.recognitionLanguages = ["ru-RU", "en-US"]
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do    { try handler.perform([request]) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func extractProducts(from text: String) -> [ReceiptProduct] {
        let lines = text.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { $0.count > 3 }

        return lines
            .filter { !isServiceLine($0) }
            .compactMap { parseLine($0) }
    }

    private func isServiceLine(_ line: String) -> Bool {
        let exact = ["ИТОГО", "ИТОГ", "СУММА", "TOTAL", "SUBTOTAL",
                     "НДС 20%", "НДС 10%", "НАЛОГ", "TAX",
                     "НАЛИЧНЫЕ", "БЕЗНАЛИЧНЫЕ", "СДАЧА", "CHANGE",
                     "КАССИР", "CASHIER", "СПАСИБО", "THANK YOU",
                     "ЧЕК №", "ЧЕКK", "RECEIPT"]
        let prefixes = ["ИНН ", "КПП ", "ФН ", "ФД ", "ФП ",
                        "HTTP", "WWW.", "TEL:", "ТЕЛ:",
                        "Г. ", "УЛ. ", "ПР. ", "ПЕР. ", "Д. "]
        let upper = line.uppercased()

        if exact.contains(where: { upper == $0 }) { return true }
        if prefixes.contains(where: { upper.hasPrefix($0) }) { return true }

        let letters = line.unicodeScalars.filter { CharacterSet.letters.contains($0) }
        if letters.isEmpty { return true }

        return false
    }

    private func parseLine(_ line: String) -> ReceiptProduct? {

        var cleaned = line
            .replacingOccurrences(of: ",", with: ".")
            .replacingOccurrences(of: " .", with: ".")
            .replacingOccurrences(of: ". ", with: ".")

        let pricePatterns = [
            #"(\d[\d\s]{0,6}\.\d{2})\s*[АВ]?\s*$"#,
            #"(\d[\d\s]{0,6}\.\d{2})\s*$"#,
            #"(\d+)\s*р\.?\s*$"#,
        ]

        var price: Double? = nil
        var nameStr = cleaned

        for pattern in pricePatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: cleaned, range: NSRange(cleaned.startIndex..., in: cleaned)) {
                let nsStr    = cleaned as NSString
                let priceStr = nsStr.substring(with: match.range(at: 1))
                    .replacingOccurrences(of: " ", with: "")
                if let val = Double(priceStr), val > 0.5, val < 100_000 {
                    price = val

                    let nameEnd = cleaned.index(cleaned.startIndex, offsetBy: match.range.location)
                    nameStr = String(cleaned[..<nameEnd])
                    break
                }
            }
        }

        nameStr = nameStr
            .replacingOccurrences(of: #"^\d+\s+"#,         with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*х\s*\d+.*$"#,   with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s*\*\s*\d+.*$"#,  with: "", options: .regularExpression)
            .replacingOccurrences(of: #"[=|\\]"#,           with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s{2,}"#,           with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)

        guard nameStr.count >= 3 else { return nil }

        return ReceiptProduct(name: nameStr, price: price)
    }
}
