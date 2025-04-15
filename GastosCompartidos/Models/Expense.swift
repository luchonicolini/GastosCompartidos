//
//  Expense.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftData
import Foundation

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var expenseDescription: String 
    var amount: Double
    var date: Date

    // Relación: Quién pagó (uno a uno/muchos con Person)
    // Si se borra la persona que pagó, ¿qué hacer? Ponerlo a nil.
    @Relationship(deleteRule: .nullify)
    var payer: Person?

    // Relación: Quiénes participaron (muchos a muchos con Person)
    // Si se borra una persona participante, simplemente se elimina de esta lista.
    // No se especifica regla de borrado explícita aquí, SwiftData maneja la relación.
    var participants: [Person]? = []

    // Relación: Grupo al que pertenece (uno a uno/muchos con Group)
    // Es el inverso de 'expenses' en Group. Requerido para la relación bidireccional.
    var group: Group?

    init(id: UUID = UUID(), description: String = "", amount: Double = 0.0, date: Date = Date(), payer: Person? = nil, participants: [Person]? = [], group: Group? = nil) {
        self.id = id
        self.expenseDescription = description
        self.amount = amount
        self.date = date
        self.payer = payer
        self.participants = participants
        self.group = group
    }

    // Propiedad calculada para facilitar el cálculo de la parte por persona
    var amountPerParticipant: Double {
        guard let participants = participants, !participants.isEmpty, amount > 0 else {
            return 0
        }
        return amount / Double(participants.count)
    }
}
