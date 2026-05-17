import SwiftUI

enum QuantityStatusStyle {
    static func icon(for status: String) -> String {
        switch status {
        case "Plenty": return "checkmark.circle.fill"
        default:       return "minus.circle.fill"
        }
    }

    static func color(for status: String) -> Color {
        switch status {
        case "Plenty": return .green
        default:       return .orange
        }
    }
}
