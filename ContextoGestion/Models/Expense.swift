//
//  Expense.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftData
import Foundation

enum SplitType: String, Codable, CaseIterable, Identifiable {
    case equally = "Igual"
    case byAmount = "Por Monto Fijo"
    case byPercentage = "Por Porcentaje"
    case byShares = "Por Partes"

    var id: String { self.rawValue }
    var localizedDescription: String { return self.rawValue }
}

// Asegúrate que NO diga 'private final class Expense'
@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var expenseDescription: String
    var amount: Double
    var date: Date

    @Relationship(deleteRule: .nullify) // Si se borra la persona pagadora, el campo queda nil
    var payer: Person?
    var participants: [Person]? = [] // Relación implícita a muchos
    var group: Group? // Relación inversa definida en Group

    var splitType: SplitType = SplitType.equally
    var splitDetailsData: Data? // Para almacenar el diccionario codificado
    var splitDetails: [UUID: Double]? { // Propiedad computada para fácil acceso
        get {
            guard let data = splitDetailsData else { return nil }
            // Usar un JSONDecoder para convertir Data a Diccionario
            return try? JSONDecoder().decode([UUID: Double].self, from: data)
        }
        set throws {
            // Usar un JSONEncoder para convertir Diccionario a Data
            // Si newValue es nil, codifica nil, lo cual resulta en nil para splitDetailsData
            do {
                splitDetailsData = try JSONEncoder().encode(newValue)
            } catch {
                throw ExpenseError.encodingSplitDetailsError(error)
            }
        }
    }

    init(id: UUID = UUID(),
         description: String = "",
         amount: Double = 0.0,
         date: Date = Date(),
         payer: Person? = nil,
         participants: [Person]? = [],
         group: Group? = nil,
         splitType: SplitType = .equally,
         splitDetails: [UUID: Double]? = nil)
    {
        self.id = id
        self.expenseDescription = description
        self.amount = amount.rounded(toPlaces: 2) // Redondear al inicializar por seguridad
        self.date = date
        self.payer = payer
        // Asegurarse de que participants no sea nil internamente si se pasa nil
        self.participants = participants ?? []
        self.group = group
        self.splitType = splitType
        // Usar el setter de la propiedad computada para codificar los detalles
        self.splitDetails = splitDetails
    }
}

