//
//  Person.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftData
import Foundation

// Asegúrate que NO diga 'private final class Person'
@Model
final class Person {
    @Attribute(.unique) var id: UUID
    var name: String
    var creationDate: Date
    

    @Relationship(inverse: \Group.members) var groups: [Group]?

    // Asegúrate que este init NO sea 'private init'
    init(id: UUID = UUID(), name: String = "", creationDate: Date = Date()) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
    }

    // --- Conformancia a Equatable y Hashable ---
    // (Necesario para usar Person en Sets o como keys en diccionarios, como en AddExpenseViewModel)

    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }
}

extension Person: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
