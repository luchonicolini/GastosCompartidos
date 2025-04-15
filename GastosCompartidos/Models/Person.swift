//
//  Person.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftData
import Foundation // Necesario para UUID si no importas otro framework que lo incluya

@Model
final class Person {
    @Attribute(.unique) var id: UUID // Identificador único
    var name: String
    var creationDate: Date

    // Relación inversa: A qué grupos pertenece esta persona
    @Relationship(inverse: \Group.members) var groups: [Group]?

    // Relación inversa: Gastos pagados por esta persona
    // Opcional, se puede calcular, pero puede ser útil para consultas rápidas
    // @Relationship(inverse: \Expense.payer) var expensesPaid: [Expense]?

    // Relación inversa: Gastos en los que participó esta persona
    // Opcional, se puede calcular
    // @Relationship(inverse: \Expense.participants) var expensesParticipated: [Expense]?

    init(id: UUID = UUID(), name: String = "", creationDate: Date = Date()) {
        self.id = id
        self.name = name
        self.creationDate = creationDate
    }

    // Para poder comparar personas fácilmente, por ejemplo en listas o selecciones
    static func == (lhs: Person, rhs: Person) -> Bool {
        lhs.id == rhs.id
    }
}

// Extensión para hacerlo Hashable, útil para usar en Sets o como keys en Diccionarios
extension Person: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
