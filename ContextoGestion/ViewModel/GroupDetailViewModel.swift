//
//  GroupDetailViewModel.swift
//  GastosPrueba
//
//  Created by Luciano Nicolini on 16/04/2025.
//


//
//  GroupDetailViewModel.swift
//  GastosPrueba
//
//  Created by Luciano Nicolini on 16/04/2025.
//

import SwiftData
import Observation
import Foundation
import SwiftUI

struct FormattedSettlement: Identifiable, Hashable {
    let id = UUID()
    let payerName: String
    let payeeName: String
    let amount: Double
    let formattedAmount: String
    let payerId: UUID
    let payeeId: UUID
}

@Observable
class GroupDetailViewModel {

    var memberBalances: [MemberBalance] = []
    private var currentGroup: Group?

    // MARK: - Group Management
    
    @MainActor
    func setGroup(_ group: Group) {
        self.currentGroup = group
        calculateBalances(for: group)
    }

    @MainActor
    func calculateBalances(for group: Group) {
        guard group == self.currentGroup else { return }
        guard let members = group.members, !members.isEmpty else {
            memberBalances = []
            return
        }
        
        let currentMemberIDs = Set(members.map { $0.id })
        var balances: [UUID: Double] = Dictionary(uniqueKeysWithValues: members.map { ($0.id, 0.0) })
        
        // Procesar gastos normales
        if let expenses = group.expenses, !expenses.isEmpty {
            processExpensesForBalances(expenses: expenses, currentMemberIDs: currentMemberIDs, balances: &balances)
        }
        
        // Procesar pagos de liquidación
        if let settlementPayments = group.settlementPayments, !settlementPayments.isEmpty {
            processSettlementPaymentsForBalances(payments: settlementPayments, currentMemberIDs: currentMemberIDs, balances: &balances)
        }
        
        updateMemberBalancesArray(from: balances, members: members)
    }
    
    // MARK: - Settlement Payment Management
    
    @MainActor
    func confirmSettlementPayment(_ settlement: FormattedSettlement, context: ModelContext) throws {
        guard let group = currentGroup else {
            throw SettlementError.noGroupSelected
        }
        
        // Validar que el monto sea positivo
        guard settlement.amount > 0 else {
            throw SettlementError.invalidAmount
        }
        
        // Crear el pago de liquidación
        let settlementPayment = SettlementPayment(
            payerId: settlement.payerId,
            payeeId: settlement.payeeId,
            amount: settlement.amount,
            group: group,
            payerName: settlement.payerName,
            payeeName: settlement.payeeName
        )
        
        // Insertar en el contexto
        context.insert(settlementPayment)
        
        // Agregar a la relación del grupo
        if group.settlementPayments == nil {
            group.settlementPayments = []
        }
        group.settlementPayments?.append(settlementPayment)
        
        // Guardar cambios
        do {
            try context.save()
        } catch {
            // Si falla el guardado, eliminar el objeto insertado
            context.delete(settlementPayment)
            throw SettlementError.databaseSaveError(error)
        }
        
        // Recalcular balances automáticamente
        calculateBalances(for: group)
    }
    
    @MainActor
    func deleteSettlementPayment(_ payment: SettlementPayment, context: ModelContext) throws {
        guard let group = currentGroup else {
            throw SettlementError.noGroupSelected
        }
        
        // Eliminar de la base de datos
        context.delete(payment)
        
        // Guardar cambios
        do {
            try context.save()
        } catch {
            throw SettlementError.databaseSaveError(error)
        }
        
        // Recalcular balances
        calculateBalances(for: group)
    }
    
    @MainActor
    func getAllSettlementPayments() -> [SettlementPayment] {
        return currentGroup?.settlementPayments ?? []
    }
    
    // MARK: - Member Management
    
    @MainActor
    func addMember(_ person: Person, to group: Group, context: ModelContext) throws {
        guard group == self.currentGroup else { return }
        guard !(group.members?.contains(where: { $0.id == person.id }) ?? false) else {
            throw PersonError.alreadyMember(person.name, group.name)
        }

        group.members?.append(person)
        calculateBalances(for: group)
    }

    @MainActor
    func removeMember(_ person: Person, from group: Group, context: ModelContext) {
        guard group == self.currentGroup else { return }
        group.members?.removeAll { $0.id == person.id }
        calculateBalances(for: group)
    }

    @MainActor
    func addNewPersonAndAddToGroup(name: String, to group: Group, context: ModelContext) throws {
        guard group == self.currentGroup else { return }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PersonError.emptyName
        }

        let newPerson = Person(name: trimmedName)
        context.insert(newPerson)

        do {
            try context.save()
            try addMember(newPerson, to: group, context: context)
        } catch let error as PersonError {
            context.delete(newPerson)
            throw error
        } catch {
            context.delete(newPerson)
            throw PersonError.databaseSaveError(error)
        }
    }

    @MainActor
    func updatePerson(person: Person, name: String, context: ModelContext) throws {
        guard currentGroup?.members?.contains(where: { $0.id == person.id }) ?? false else {
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw PersonError.emptyName
        }
        person.name = trimmedName
        
        if let group = currentGroup {
            calculateBalances(for: group)
        }
    }
    
    // MARK: - Expense Management
    
    @MainActor
    func deleteExpense(_ expense: Expense, context: ModelContext) {
        guard let group = expense.group, group == self.currentGroup else { return }
        context.delete(expense)
        calculateBalances(for: group)
    }
    
    // MARK: - Settlement Suggestions
    
    @MainActor
    func suggestSettlements() -> [String] {
        let balancesToSettle = memberBalances.filter { abs($0.balance) > 0.01 }
        guard !balancesToSettle.isEmpty else { return ["¡Todas las cuentas están saldadas!"] }

        var settlements: [String] = []
        var tempDebtors = balancesToSettle.filter { $0.balance < -0.01 }.sorted { $0.balance < $1.balance }
        var tempCreditors = balancesToSettle.filter { $0.balance > 0.01 }.sorted { $0.balance > $1.balance }

        let formatter = createCurrencyFormatter()
        
        while !tempDebtors.isEmpty && !tempCreditors.isEmpty {
            guard var currentDebtor = tempDebtors.first, var currentCreditor = tempCreditors.first else { break }
            tempDebtors.removeFirst()
            tempCreditors.removeFirst()

            let amountToTransfer = min(abs(currentDebtor.balance), currentCreditor.balance).rounded(toPlaces: 2)

            if amountToTransfer < 0.01 {
                if abs(currentDebtor.balance) >= 0.01 { insertSorted(currentDebtor, into: &tempDebtors) { $0.balance >= $1.balance } }
                if currentCreditor.balance >= 0.01 { insertSorted(currentCreditor, into: &tempCreditors) { $0.balance <= $1.balance } }
                continue
            }

            let formattedAmount = formatter.string(from: amountToTransfer as NSNumber) ?? "\(String(format: "%.2f", amountToTransfer))"
            settlements.append("\(currentDebtor.name) paga \(formattedAmount) a \(currentCreditor.name)")

            updateRemainingBalances(debtor: &currentDebtor, creditor: &currentCreditor,
                                   amount: amountToTransfer, tempDebtors: &tempDebtors,
                                   tempCreditors: &tempCreditors)
        }

        return settlements.isEmpty ? ["¡Todas las cuentas están saldadas!"] : settlements
    }

    @MainActor
    func suggestFormattedSettlements() -> [FormattedSettlement] {
        let balancesToSettle = memberBalances.filter { abs($0.balance) > 0.01 }
        guard !balancesToSettle.isEmpty else { return [] }

        var Fsettlements: [FormattedSettlement] = []
        var tempDebtors = balancesToSettle.filter { $0.balance < -0.01 }.sorted { $0.balance < $1.balance }
        var tempCreditors = balancesToSettle.filter { $0.balance > 0.01 }.sorted { $0.balance > $1.balance }

        let formatter = createCurrencyFormatter()

        while !tempDebtors.isEmpty && !tempCreditors.isEmpty {
            guard var currentDebtor = tempDebtors.first, var currentCreditor = tempCreditors.first else { break }
            tempDebtors.removeFirst()
            tempCreditors.removeFirst()

            let amountToTransfer = min(abs(currentDebtor.balance), currentCreditor.balance).rounded(toPlaces: 2)

            if amountToTransfer < 0.01 {
                if abs(currentDebtor.balance) >= 0.01 { insertSorted(currentDebtor, into: &tempDebtors) { $0.balance >= $1.balance } }
                if currentCreditor.balance >= 0.01 { insertSorted(currentCreditor, into: &tempCreditors) { $0.balance <= $1.balance } }
                continue
            }

            let formattedAmountStr = formatter.string(from: amountToTransfer as NSNumber) ?? "\(String(format: "%.2f", amountToTransfer))"
            
            Fsettlements.append(FormattedSettlement(
                payerName: currentDebtor.name,
                payeeName: currentCreditor.name,
                amount: amountToTransfer,
                formattedAmount: formattedAmountStr,
                payerId: currentDebtor.id,
                payeeId: currentCreditor.id
            ))

            currentDebtor.balance = (currentDebtor.balance + amountToTransfer).rounded(toPlaces: 2)
            currentCreditor.balance = (currentCreditor.balance - amountToTransfer).rounded(toPlaces: 2)

            if abs(currentDebtor.balance) >= 0.01 {
                insertSorted(currentDebtor, into: &tempDebtors) { $0.balance >= $1.balance }
            }
            if currentCreditor.balance >= 0.01 {
                insertSorted(currentCreditor, into: &tempCreditors) { $0.balance <= $1.balance }
            }
        }
        return Fsettlements
    }
    
    // MARK: - Private Helper Functions
    
    private func processSettlementPaymentsForBalances(payments: [SettlementPayment], currentMemberIDs: Set<UUID>, balances: inout [UUID: Double]) {
        for payment in payments {
            // El pagador reduce su deuda (suma positiva al balance)
            if currentMemberIDs.contains(payment.payerId) {
                balances[payment.payerId, default: 0.0] += payment.amount
            }
            // El receptor reduce su crédito (resta del balance)
            if currentMemberIDs.contains(payment.payeeId) {
                balances[payment.payeeId, default: 0.0] -= payment.amount
            }
        }
    }
    
    private func createCurrencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter
    }
    
    private func updateRemainingBalances(debtor: inout MemberBalance, creditor: inout MemberBalance,
                                        amount: Double, tempDebtors: inout [MemberBalance],
                                        tempCreditors: inout [MemberBalance]) {
        debtor.balance = (debtor.balance + amount).rounded(toPlaces: 2)
        creditor.balance = (creditor.balance - amount).rounded(toPlaces: 2)

        if abs(debtor.balance) >= 0.01 {
            insertSorted(debtor, into: &tempDebtors) { $0.balance >= $1.balance }
        }
        if creditor.balance >= 0.01 {
            insertSorted(creditor, into: &tempCreditors) { $0.balance <= $1.balance }
        }
    }
    
    private func insertSorted<T>(_ element: T, into array: inout [T], where condition: (T, T) -> Bool) {
        if let index = array.firstIndex(where: { condition($0, element) }) {
            array.insert(element, at: index)
        } else {
            array.append(element)
        }
    }
    
    @MainActor
    private func updateMemberBalancesArray(from balanceDict: [UUID: Double], members: [Person]) {
        memberBalances = members.map { member in
            MemberBalance(
                id: member.id,
                name: member.name,
                balance: (balanceDict[member.id] ?? 0.0).rounded(toPlaces: 2)
            )
        }
        .sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    
    private func processExpensesForBalances(expenses: [Expense], currentMemberIDs: Set<UUID>, balances: inout [UUID: Double]) {
        for expense in expenses {
            guard let payer = expense.payer, expense.amount > 0 else { continue }
            
            if currentMemberIDs.contains(payer.id) {
                balances[payer.id, default: 0.0] += expense.amount
            }
            
            guard let originalParticipants = expense.participants, !originalParticipants.isEmpty else { continue }
            
            let currentParticipantsInExpense = originalParticipants.filter { currentMemberIDs.contains($0.id) }
            guard !currentParticipantsInExpense.isEmpty else { continue }
            
            let sharesToDebit = calculateShares(
                expense: expense,
                participants: currentParticipantsInExpense
            )
            
            for (personId, shareAmount) in sharesToDebit {
                if currentMemberIDs.contains(personId) {
                    balances[personId, default: 0.0] -= shareAmount
                }
            }
        }
    }
    
    private func calculateShares(expense: Expense, participants: [Person]) -> [UUID: Double] {
        switch expense.splitType {
        case .equally:
            return calculateEqualShares(expense: expense, participants: participants)
        case .byAmount:
            return calculateAmountShares(expense: expense, participants: participants)
        case .byPercentage:
            return calculatePercentageShares(expense: expense, participants: participants)
        case .byShares:
            return calculateProportionalShares(expense: expense, participants: participants)
        }
    }
    
    private func calculateEqualShares(expense: Expense, participants: [Person]) -> [UUID: Double] {
        var sharesToDebit: [UUID: Double] = [:]
        let expenseAmountRounded = expense.amount.rounded(toPlaces: 2)
        let participantCount = Double(participants.count)
        
        if participantCount > 0 {
            let share = (expense.amount / participantCount).rounded(toPlaces: 2)
            var totalRoundedShare: Double = 0
            
            for participant in participants {
                sharesToDebit[participant.id] = share
                totalRoundedShare += share
            }
            
            let roundingDifference = (expenseAmountRounded - totalRoundedShare).rounded(toPlaces: 2)
            if abs(roundingDifference) > 0.001, let firstParticipant = participants.first {
                sharesToDebit[firstParticipant.id]? += roundingDifference
            }
        }
        
        return sharesToDebit
    }
    
    private func calculateAmountShares(expense: Expense, participants: [Person]) -> [UUID: Double] {
        var sharesToDebit: [UUID: Double] = [:]
        let expenseAmountRounded = expense.amount.rounded(toPlaces: 2)
        
        if let details = expense.splitDetails {
            var calculatedSum: Double = 0
            for participant in participants {
                let specificAmount = (details[participant.id] ?? 0.0).rounded(toPlaces: 2)
                sharesToDebit[participant.id] = specificAmount
                calculatedSum += specificAmount
            }
            
            if abs(calculatedSum - expenseAmountRounded) > 0.01 {
                // Log inconsistency but continue
                print("Warning: Split details sum (\(calculatedSum)) doesn't match expense amount (\(expenseAmountRounded))")
            }
        } else {
            return calculateEqualShares(expense: expense, participants: participants)
        }
        
        return sharesToDebit
    }
    
    private func calculatePercentageShares(expense: Expense, participants: [Person]) -> [UUID: Double] {
        var sharesToDebit: [UUID: Double] = [:]
        let expenseAmountRounded = expense.amount.rounded(toPlaces: 2)
        
        if let details = expense.splitDetails {
            var calculatedSumAmount: Double = 0
            for participant in participants {
                let percentage = details[participant.id] ?? 0.0
                let calculatedAmount = (expense.amount * (percentage / 100.0)).rounded(toPlaces: 2)
                sharesToDebit[participant.id] = calculatedAmount
                calculatedSumAmount += calculatedAmount
            }
            
            let roundingDifference = (expenseAmountRounded - calculatedSumAmount).rounded(toPlaces: 2)
            if abs(roundingDifference) > 0.001, let firstParticipant = participants.first {
                sharesToDebit[firstParticipant.id]? += roundingDifference
            }
        } else {
            return calculateEqualShares(expense: expense, participants: participants)
        }
        
        return sharesToDebit
    }
    
    private func calculateProportionalShares(expense: Expense, participants: [Person]) -> [UUID: Double] {
        var sharesToDebit: [UUID: Double] = [:]
        let expenseAmountRounded = expense.amount.rounded(toPlaces: 2)
        
        if let details = expense.splitDetails {
            var totalShares: Double = 0
            for participant in participants {
                totalShares += details[participant.id] ?? 0.0
            }
            
            if totalShares > 0 {
                var calculatedSumAmount: Double = 0
                for participant in participants {
                    let participantShares = details[participant.id] ?? 0.0
                    let calculatedAmount = (expense.amount * (participantShares / totalShares)).rounded(toPlaces: 2)
                    sharesToDebit[participant.id] = calculatedAmount
                    calculatedSumAmount += calculatedAmount
                }
                
                let roundingDifference = (expenseAmountRounded - calculatedSumAmount).rounded(toPlaces: 2)
                if abs(roundingDifference) > 0.001, let firstParticipant = participants.first {
                    sharesToDebit[firstParticipant.id]? += roundingDifference
                }
            } else {
                return calculateEqualShares(expense: expense, participants: participants)
            }
        } else {
            return calculateEqualShares(expense: expense, participants: participants)
        }
        
        return sharesToDebit
    }
}

// MARK: - Error Handling

enum SettlementError: LocalizedError {
    case noGroupSelected
    case invalidAmount
    case databaseSaveError(Error)
    case paymentNotFound
    
    var errorDescription: String? {
        switch self {
        case .noGroupSelected:
            return "No hay grupo seleccionado"
        case .invalidAmount:
            return "El monto del pago debe ser mayor a cero"
        case .databaseSaveError(let error):
            return "Error al guardar en la base de datos: \(error.localizedDescription)"
        case .paymentNotFound:
            return "Pago de liquidación no encontrado"
        }
    }
}

