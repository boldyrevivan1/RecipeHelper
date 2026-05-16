//
//  QuantityStatusStyle.swift
//  RecipeHelper
//
//  Tiny helper so views can render icon + color for an FSProduct's
//  quantityStatus string ("Plenty" / "Medium" / ...).
//  Replaces the old ProductQuantityStatus enum that lived inside the
//  retired SwiftData Product model.
//

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
