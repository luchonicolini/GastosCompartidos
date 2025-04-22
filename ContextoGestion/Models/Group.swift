//
//  Group.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftData
import SwiftUI

// Asegúrate que NO diga 'private final class Group'
@Model
final class Group {
    @Attribute(.unique) var id: UUID
    var name: String
    var creationDate: Date
    var iconName: String?
    var colorHex: String?

    var members: [Person]? = []
    @Relationship(deleteRule: .cascade, inverse: \Expense.group)
    var expenses: [Expense]? = []

    var displayIcon: Image {
        Image(systemName: iconName ?? "person.3.sequence.fill")
    }

    var displayColor: Color {
        if let hex = colorHex, let color = Color(hex: hex) {
            return color
        }
        return .blue
    }

    // Asegúrate que este init NO sea 'private init'
    init(id: UUID = UUID(),
         name: String = "",
         creationDate: Date = Date(),
         iconName: String? = nil,
         colorHex: String? = nil)
    {
        self.id = id
        self.name = name
        self.creationDate = creationDate
        self.iconName = iconName
        self.colorHex = colorHex
    }
}
