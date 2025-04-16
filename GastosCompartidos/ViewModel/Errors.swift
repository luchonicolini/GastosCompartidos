//
//  Errors.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 15/04/2025.
//

import SwiftUI

// Errores posibles al añadir/validar un Gasto
enum ExpenseError: Error, LocalizedError {
    case emptyDescription
    case invalidAmountFormat // Formato de número incorrecto
    case nonPositiveAmount // Monto <= 0
    case noPayerSelected
    case noParticipantsSelected
    case calculationError // Si hubiera algún cálculo complejo que fallara
    case databaseSaveError(Error) // Para errores al guardar en SwiftData

    // Mensajes para el usuario (LocalizedError)
    var errorDescription: String? {
        switch self {
        case .emptyDescription:
            return "La descripción no puede estar vacía."
        case .invalidAmountFormat:
            return "El formato del monto es inválido. Usa el separador decimal de tu región."
        case .nonPositiveAmount:
            return "El monto debe ser mayor que cero."
        case .noPayerSelected:
            return "Por favor, selecciona quién pagó el gasto."
        case .noParticipantsSelected:
            return "Debe haber al menos un participante seleccionado."
        case .calculationError:
            return "Hubo un error al calcular los detalles del gasto."
        case .databaseSaveError(let underlyingError):
            // Podrías loggear 'underlyingError' para depuración
            print("Database Save Error: \(underlyingError.localizedDescription)")
            return "No se pudo guardar el gasto. Inténtalo de nuevo."
        }
    }

    // Podrías añadir también `failureReason`, `recoverySuggestion` si quieres más detalle
}

// Errores posibles al añadir/validar un Grupo
enum GroupError: Error, LocalizedError {
    case emptyName
    case databaseSaveError(Error)
    // ... otros errores si aplican

    var errorDescription: String? {
        switch self {
        case .emptyName:
            return "El nombre del grupo no puede estar vacío."
        case .databaseSaveError(let underlyingError):
            print("Database Save Error: \(underlyingError.localizedDescription)")
            return "No se pudo guardar el grupo. Inténtalo de nuevo."
        }
    }
}

// Errores posibles al añadir/validar una Persona
enum PersonError: Error, LocalizedError {
     case emptyName
     case nameAlreadyExists(String) // Ejemplo si quisieras validar nombres únicos
     case databaseSaveError(Error)
     // ... otros errores

     var errorDescription: String? {
         switch self {
         case .emptyName:
             return "El nombre de la persona no puede estar vacío."
         case .nameAlreadyExists(let name):
             return "Ya existe una persona llamada '\(name)'."
         case .databaseSaveError(let underlyingError):
             print("Database Save Error: \(underlyingError.localizedDescription)")
             return "No se pudo guardar la persona. Inténtalo de nuevo."
         }
     }
 }
