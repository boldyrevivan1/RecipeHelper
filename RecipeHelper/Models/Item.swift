//
//  Item.swift
//  RecipeHelper
//
//  Created by Иван Болдырев on 29.01.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
