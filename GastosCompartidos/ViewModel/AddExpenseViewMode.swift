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
    @MainActor // Asegurar que se ejecuta en el hilo principal si interactúa con UI/SwiftData
    func saveExpense(for group: Group, context: ModelContext) -> Bool {
        errorMessage = nil // Limpiar errores previos
        let trimmedAmountString = amountString.trimmingCharacters(in: .whitespaces)

        // --- Validación ---
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "La descripción no puede estar vacía."
            return false
        }
        // Validar que el monto sea un número Double válido y mayor que cero
        guard let amount = Double(trimmedAmountString), amount > 0 else {
            errorMessage = "Introduce un monto numérico válido y mayor que cero."
            // Considerar usar NumberFormatter para validar formatos locales si es necesario
            return false
        }
        guard let payerId = selectedPayerId, let payer = groupMembers.first(where: { $0.id == payerId }) else {
            errorMessage = "Selecciona quién pagó."
            return false
        }
        // Obtener los objetos Person de los participantes seleccionados
        let participants = groupMembers.filter { selectedParticipantIds.contains($0.id) }
        guard !participants.isEmpty else {
            errorMessage = "Selecciona al menos un participante."
            return false
        }

        // --- Creación y guardado ---
        let newExpense = Expense(
            description: description.trimmingCharacters(in: .whitespacesAndNewlines), // Guardar versión limpia
            amount: amount,
            date: date,
            payer: payer,
            participants: participants, // Guardar el array de Person filtrado
            group: group
        )
        context.insert(newExpense)
        print("Gasto '\(newExpense.expenseDescription)' preparado para guardar.")

        // El guardado real lo maneja SwiftData. Asumimos éxito aquí si no hay excepciones.

        // Limpiar el formulario para la próxima entrada (opcional pero útil)
        // Se podría llamar `clearForm()` aquí, pero si el usuario quiere añadir
        // varios gastos similares, puede ser molesto. Mejor no limpiarlo automáticamente.
        // La vista puede decidir si limpiar o no después de llamar a saveExpense.

        return true // Éxito
    }
}
