//
//  AddExpenseViewMode.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

// ViewModels/AddExpenseViewModel.swift
import SwiftUI
import SwiftData


// ViewModels/AddExpenseViewModel.swift

import SwiftUI
import SwiftData

@Observable
class AddExpenseViewModel {

    // --- Propiedades de Estado ---
    var description: String = ""
    var amountString: String = ""
    var date: Date = Date()
    var selectedPayerId: UUID?
    var selectedParticipantIds: Set<UUID> = []
    var errorMessage: String?

    // --- Propiedad para guardar el gasto que se está editando ---
    private var expenseToEdit: Expense? // Si es nil, estamos en modo "Añadir"

    // Referencia a los miembros del grupo
    private var groupMembers: [Person] = []

    // --- Configuración inicial (Setup) ---
    func setup(expense: Expense? = nil, members: [Person]) {
        self.expenseToEdit = expense
        self.groupMembers = members
        self.errorMessage = nil

        if let expense = expense {
            // --- Modo Editar: Pre-cargar datos ---
            print("Editando gasto: \(expense.expenseDescription)")
            description = expense.expenseDescription
            // Usar NumberFormatter para mostrar el monto inicial también podría ser más robusto,
            // pero String(format:) es más simple para empezar.
            amountString = String(format: "%.2f", expense.amount).replacingOccurrences(of: ",", with: ".")
            date = expense.date
            selectedPayerId = expense.payer?.id
            selectedParticipantIds = Set(expense.participants?.map { $0.id } ?? [])
        } else {
            // --- Modo Añadir: Limpiar/Resetear ---
            print("Añadiendo nuevo gasto")
            clearForm()
        }
    }

    // --- Obtener Miembros Disponibles ---
    func availableMembers() -> [Person] {
        return groupMembers
    }

    // --- Limpiar Formulario ---
    func clearForm() {
        description = ""
        amountString = ""
        date = Date()
        selectedPayerId = nil
        selectedParticipantIds = []
        errorMessage = nil
        // No limpiar expenseToEdit aquí
    }

    // --- Guardar/Actualizar Gasto (CON LA CORRECCIÓN DEL ERROR) ---
    @MainActor
    func saveExpense(for group: Group, context: ModelContext) -> Bool {
        errorMessage = nil // Limpiar errores previos
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAmountString = amountString.trimmingCharacters(in: .whitespaces)

        // --- Validación ---
        guard !trimmedDescription.isEmpty else {
            errorMessage = "La descripción no puede estar vacía."
            return false
        }

        // --- Conversión y Validación de Monto con NumberFormatter (CORREGIDA) ---
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Reconoce formato local

        // 1. Intentar convertir el String a NSNumber?
        guard let number = formatter.number(from: trimmedAmountString) else {
            // Falló la conversión inicial (formato inválido)
            errorMessage = "Formato de monto inválido (usa el separador decimal de tu región)."
            return false
        }

        // 2. Obtener el valor Double (number ya NO es opcional aquí)
        let amount = number.doubleValue

        // 3. Verificar si el valor Double es > 0
        guard amount > 0 else {
            // El número era válido, pero no > 0
            errorMessage = "El monto debe ser mayor que cero."
            return false
        }
        // --- Fin Conversión de Monto ---
        // Si llegamos aquí, 'amount' es un Double válido y > 0

        // --- Resto de las Validaciones (Pagador, Participantes) ---
        guard let payerId = selectedPayerId, let payer = groupMembers.first(where: { $0.id == payerId }) else {
            errorMessage = "Selecciona quién pagó."
            return false
        }
        let participants = groupMembers.filter { selectedParticipantIds.contains($0.id) }
        guard !participants.isEmpty else {
            errorMessage = "Selecciona al menos un participante."
            return false
        }

        // --- Lógica de Guardado/Actualización ---
        if let expense = expenseToEdit {
            // --- MODO EDITAR: Actualizar el objeto existente ---
            print("Actualizando gasto: \(expense.expenseDescription)")
            expense.expenseDescription = trimmedDescription
            expense.amount = amount // Usar el 'amount' validado
            expense.date = date
            expense.payer = payer
            expense.participants = participants
            print("Gasto actualizado.")

        } else {
            // --- MODO AÑADIR: Crear y insertar nuevo objeto ---
            print("Guardando NUEVO gasto.")
            let newExpense = Expense(
                description: trimmedDescription,
                amount: amount, // Usar el 'amount' validado
                date: date,
                payer: payer,
                participants: participants,
                group: group
            )
            context.insert(newExpense)
            print("Nuevo gasto '\(newExpense.expenseDescription)' insertado en contexto.")
        }

        return true // Éxito
    }
} // Fin de la clase AddExpenseViewModel
