//
//  GroupDetailViewModel.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI
import SwiftData

// Estructura para almacenar el balance calculado de cada miembro
struct MemberBalance: Identifiable, Hashable {
    let id: UUID // Usa el ID de la persona para identificación
    let name: String
    let balance: Double // Positivo = le deben, Negativo = debe
}

@Observable // El nuevo macro de observación
class GroupDetailViewModel {
    // Almacenar los balances calculados para que la vista los muestre
    var memberBalances: [MemberBalance] = []

    // --- Lógica de Cálculo de Balances ---
    func calculateBalances(for group: Group) {
        guard let members = group.members, !members.isEmpty else {
            memberBalances = []
            return
        }

        var balances: [UUID: Double] = [:]
        for member in members { balances[member.id] = 0.0 }

        guard let expenses = group.expenses else {
            updateMemberBalancesArray(from: balances, members: members)
            return
        }

        for expense in expenses {
            guard let payer = expense.payer, let participants = expense.participants, !participants.isEmpty, expense.amount > 0 else {
                continue // Ignorar gastos inválidos
            }
            let amountPerParticipant = expense.amountPerParticipant
            // Sumar al pagador
            balances[payer.id, default: 0.0] += expense.amount
            // Restar a los participantes
            for participant in participants {
                 // Solo restar si el participante sigue siendo miembro del grupo
                 // (Podría haber sido eliminado)
                 if members.contains(where: { $0.id == participant.id }) {
                    balances[participant.id, default: 0.0] -= amountPerParticipant
                 }
            }
        }
        updateMemberBalancesArray(from: balances, members: members)
        print("Balances calculados: \(memberBalances)")
    }

    // Función auxiliar para convertir el diccionario de balances al array
    private func updateMemberBalancesArray(from balanceDict: [UUID: Double], members: [Person]) {
         memberBalances = members.map { member in
            MemberBalance(
                id: member.id,
                name: member.name,
                balance: balanceDict[member.id] ?? 0.0
            )
        }
        .sorted { $0.name < $1.name } // Ordenar alfabéticamente
    }

    // --- Lógica para Miembros (Actualizada/Confirmada) ---
    func addMember(_ person: Person, to group: Group, context: ModelContext) {
        guard !(group.members?.contains(where: { $0.id == person.id }) ?? false) else {
             print("WARN: La persona '\(person.name)' ya es miembro de '\(group.name)'")
             return
        }
        // Añadir a la relación del grupo. SwiftData maneja la inversa si está configurada.
        group.members?.append(person)
        print("Miembro '\(person.name)' añadido a '\(group.name)'")
        // El .onChange en la vista se encargará de recalcular balances.
    }

    func removeMember(_ person: Person, from group: Group, context: ModelContext) {
        // Eliminar la relación. SwiftData maneja la inversa.
        group.members?.removeAll { $0.id == person.id }
        print("Miembro '\(person.name)' eliminado de '\(group.name)'")
        // El .onChange en la vista se encargará de recalcular balances.
        // Considerar el impacto en gastos pasados donde participó/pagó si es necesario.
    }

    // --- NUEVA Lógica para añadir nueva persona ---
    func addNewPersonAndAddToGroup(name: String, to group: Group, context: ModelContext) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        // Opcional: Verificar si ya existe una persona con ese nombre globalmente
        // let predicate = #Predicate<Person> { $0.name == trimmedName }
        // var descriptor = FetchDescriptor(predicate: predicate)
        // if let existing = try? context.fetch(descriptor).first {
        //      print("WARN: Ya existe una persona llamada \(trimmedName). Añadiendo la existente.")
        //      addMember(existing, to: group, context: context)
        //      return
        // }

        // 1. Crear la nueva Persona
        print("--> Creando nueva persona: \(trimmedName)")
        let newPerson = Person(name: trimmedName)

        // 2. Insertar la nueva persona en el contexto
        context.insert(newPerson)
        print("--> Nueva persona insertada en el contexto.")

        // 3. Añadir la nueva persona al grupo actual
        addMember(newPerson, to: group, context: context)
    }

    // --- Lógica para Gastos ---
    func deleteExpense(_ expense: Expense, context: ModelContext) {
         if let group = expense.group { // Guardar referencia al grupo antes de borrar
            context.delete(expense)
            print("Gasto '\(expense.expenseDescription)' eliminado.")
            // El .onChange(of: group.expenses) en la vista recalculará.
         } else {
             // Si el gasto no tiene grupo (inesperado), solo borrarlo.
             context.delete(expense)
             print("Gasto '\(expense.expenseDescription)' sin grupo eliminado.")
         }
    }

    // --- Lógica de Liquidación (Simplificada, sin cambios) ---
    func suggestSettlements() -> [String] {
        var balancesToSettle = memberBalances.filter { abs($0.balance) > 0.01 }
        var settlements: [String] = []
        var debtors = balancesToSettle.filter { $0.balance < 0 }.sorted { $0.balance < $1.balance }
        var creditors = balancesToSettle.filter { $0.balance > 0 }.sorted { $0.balance > $1.balance }

        while let debtor = debtors.first, let creditor = creditors.first {
             if abs(debtor.balance) < 0.01 { debtors.removeFirst(); continue }
             if creditor.balance < 0.01 { creditors.removeFirst(); continue }

            let amountToTransfer = min(abs(debtor.balance), creditor.balance)

            // Formatear usando el mismo formateador de la vista para consistencia
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            let formattedAmount = formatter.string(from: amountToTransfer as NSNumber) ?? "\(String(format: "%.2f", amountToTransfer))"

            settlements.append("\(debtor.name) paga \(formattedAmount) a \(creditor.name)")

            // Actualizar balances temporales
            let debtorIndex = debtors.firstIndex(where: {$0.id == debtor.id})!
            let creditorIndex = creditors.firstIndex(where: {$0.id == creditor.id})!

            debtors[debtorIndex] = MemberBalance(id: debtor.id, name: debtor.name, balance: debtor.balance + amountToTransfer)
            creditors[creditorIndex] = MemberBalance(id: creditor.id, name: creditor.name, balance: creditor.balance - amountToTransfer)


            // Reordenar o eliminar si ya están saldados
             if abs(debtors[debtorIndex].balance) < 0.01 { debtors.remove(at: debtorIndex) } else { debtors.sort { $0.balance < $1.balance }}
             if creditors[creditorIndex].balance < 0.01 { creditors.remove(at: creditorIndex) } else { creditors.sort { $0.balance > $1.balance }}

             // Romper si algo sale mal para evitar bucle infinito
             if amountToTransfer < 0.01 { break }
        }
        print("Sugerencias de liquidación: \(settlements)")
        return settlements
    }
}
