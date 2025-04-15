//
//  Group.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftData
import Foundation

@Model
final class Group {
    @Attribute(.unique) var id: UUID
    var name: String
    var creationDate: Date

    // Relación: Miembros del grupo (muchos a muchos con Person)
    // No se especifica regla de borrado aquí, se maneja en Person si es necesario
    // o se gestiona manualmente al borrar un grupo o persona.
    var members: [Person]? = []

    // Relación: Gastos del grupo (uno a muchos con Expense)
    // Si se borra el grupo, se borran sus gastos asociados.
    @Relationship(deleteRule: .cascade, inverse: \Expense.group)
    var expenses: [Expense]? = []

    init(id: UUID = UUID(), name: String = "", creationDate: Date = Date()) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
    }
}
