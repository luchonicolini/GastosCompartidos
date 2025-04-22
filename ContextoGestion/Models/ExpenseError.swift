//
//  ExpenseError.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import Foundation

// Errores posibles al añadir/validar un Gasto
enum ExpenseError: Error, LocalizedError {
    case emptyDescription
    case invalidAmountFormat
    case nonPositiveAmount
    case noPayerSelected
    case noParticipantsSelected
    case calculationError // Para errores específicos de la lógica de división no equitativa
    case splitInputMissingOrInvalid(String) // Nuevo: Para input faltante/inválido en división
    case splitAmountSumMismatch(Double, Double) // Nuevo: Suma de montos no cuadra
    case splitPercentageSumMismatch(Double) // Nuevo: Suma de % no es 100
    case splitSharesSumInvalid // Nuevo: Suma de partes es <= 0
    case encodingSplitDetailsError(Error) // Nuevo: Error al codificar detalles
    case databaseSaveError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyDescription:
            return "La descripción no puede estar vacía."
        case .invalidAmountFormat:
            return "El formato del monto es inválido."
        case .nonPositiveAmount:
            return "El monto debe ser mayor que cero."
        case .noPayerSelected:
            return "Selecciona quién pagó."
        case .noParticipantsSelected:
            return "Selecciona al menos un participante."
        case .calculationError:
             return "Hubo un error al calcular los detalles de la división."
        case .splitInputMissingOrInvalid(let name):
            return "Falta valor o formato inválido para \(name) en la división."
        case .splitAmountSumMismatch(let sum, let total):
             return "La suma de los montos de la división ($\(String(format: "%.2f", sum))) no coincide con el total del gasto ($\(String(format: "%.2f", total)))."
        case .splitPercentageSumMismatch(let sum):
             return "La suma de los porcentajes de la división (\(String(format: "%.1f", sum))%) no es 100%."
        case .splitSharesSumInvalid:
            return "La suma de las partes/proporciones debe ser mayor que cero."
        case .encodingSplitDetailsError:
             return "Hubo un error interno al preparar los detalles de la división."
        case .databaseSaveError:
            return "No se pudo guardar el gasto en la base de datos."
        }
    }
}

// Errores posibles al añadir/validar un Grupo
enum GroupError: Error, LocalizedError {
    case emptyName
    case databaseSaveError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "El nombre del grupo no puede estar vacío."
        case .databaseSaveError:
            return "No se pudo guardar el grupo en la base de datos."
        }
    }
}

// Errores posibles al añadir/validar una Persona
enum PersonError: Error, LocalizedError {
    case emptyName
    case alreadyMember(String, String) // Nuevo: Persona ya es miembro del grupo
    case databaseSaveError(Error)

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "El nombre de la persona no puede estar vacío."
        case .alreadyMember(let personName, let groupName):
             return "'\(personName)' ya es miembro del grupo '\(groupName)'."
        case .databaseSaveError:
            return "No se pudo guardar la persona en la base de datos."
        }
    }
}

// Estructura auxiliar (sin cambios)
struct MemberBalance: Identifiable, Hashable {
    let id: UUID
    let name: String
    var balance: Double
}

// Extensión Double (sin cambios)
extension Double {
    func rounded(toPlaces places: Int) -> Double {
        guard places >= 0 else { return self }
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
