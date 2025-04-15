//
//  AddExpenseViewMode.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

// ViewModels/AddExpenseViewModel.swift
import SwiftUI
import SwiftData

@Observable
class AddExpenseViewModel {
    // Propiedades para enlazar con los campos del formulario
    var description: String = ""
    var amountString: String = "" // Usar String para manejar mejor la entrada
    var date: Date = Date()
    var selectedPayerId: UUID?
    var selectedParticipantIds: Set<UUID> = []

    // Estado para validación o errores
    var errorMessage: String?

    // Referencia a los miembros del grupo (se establecen en setup)
    private var groupMembers: [Person] = []

    // Método para configurar el ViewModel con los miembros del grupo
    func setup(members: [Person]) {
        self.groupMembers = members
        // Opcional: Preseleccionar pagador/participantes por defecto si se desea
        // self.selectedPayerId = members.first?.id
        // self.selectedParticipantIds = Set(members.map { $0.id })
    }

    // Función para obtener los miembros disponibles (para Pickers en la vista)
    func availableMembers() -> [Person] {
        return groupMembers
    }

    // Función para limpiar el formulario
    func clearForm() {
        description = ""
        amountString = ""
        date = Date() // Resetear a fecha actual
        selectedPayerId = nil
        selectedParticipantIds = []
        errorMessage = nil
    }

    // Función para guardar el gasto
    @MainActor
    func saveExpense(for group: Group, context: ModelContext) -> Bool {
        errorMessage = nil
        let trimmedAmountString = amountString.trimmingCharacters(in: .whitespaces)

        // --- Validación ---
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "La descripción no puede estar vacía."
            return false
        }

        // --- Conversión y Validación de Monto con NumberFormatter (Corregida) ---
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal // Reconoce formato local

        // 1. Intentar convertir el String a NSNumber?
        guard let number = formatter.number(from: trimmedAmountString) else {
            // Falló la conversión inicial (formato inválido)
            errorMessage = "Formato de monto inválido (usa el separador decimal de tu región)."
            return false
        }

        // 2. Obtener el valor Double y verificar si es > 0
        let amount = number.doubleValue // number aquí ya NO es opcional
        guard amount > 0 else {
            // El número era válido, pero no > 0
            errorMessage = "El monto debe ser mayor que cero."
            return false
        }
        // --- Fin Conversión de Monto ---
        // Si llegamos aquí, 'amount' es un Double válido y > 0

        guard let payerId = selectedPayerId, let payer = groupMembers.first(where: { $0.id == payerId }) else {
            errorMessage = "Selecciona quién pagó."
            return false
        }
        let participants = groupMembers.filter { selectedParticipantIds.contains($0.id) }
        guard !participants.isEmpty else {
            errorMessage = "Selecciona al menos un participante."
            return false
        }

        // --- Creación y guardado ---
        let newExpense = Expense(
            description: description.trimmingCharacters(in: .whitespacesAndNewlines),
            amount: amount, // Usar el monto Double validado
            date: date,
            payer: payer,
            participants: participants,
            group: group
        )
        context.insert(newExpense)
        print("Gasto '\(newExpense.expenseDescription)' preparado para guardar.")

        return true // Éxito
    }
}
