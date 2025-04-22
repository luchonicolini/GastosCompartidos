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

@Observable
class GroupDetailViewModel {

    var memberBalances: [MemberBalance] = []
    private var currentGroup: Group?

    // MARK: - Public API
    
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
        
        guard let expenses = group.expenses, !expenses.isEmpty else {
            updateMemberBalancesArray(from: balances, members: members)
            return
        }
        
        processExpensesForBalances(expenses: expenses, currentMemberIDs: currentMemberIDs, balances: &balances)
        updateMemberBalancesArray(from: balances, members: members)
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
            print("Database Save Error on addNewPersonAndAddToGroup: \(error.localizedDescription)")
            throw PersonError.databaseSaveError(error)
        }
    }

    @MainActor
    func updatePerson(person: Person, name: String, context: ModelContext) throws {
        guard currentGroup?.members?.contains(where: { $0.id == person.id }) ?? false else {
            print("WARN: Attempting to edit person not in the current group context.")
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
    
    // MARK: - Settlement Calculations
    
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
                if abs(currentDebtor.balance) >= 0.01 { tempDebtors.insert(currentDebtor, at: 0) }
                if currentCreditor.balance >= 0.01 { tempCreditors.insert(currentCreditor, at: 0) }
                continue
            }

            let formattedAmount = formatter.string(from: amountToTransfer as NSNumber) ?? "\(String(format: "%.2f", amountToTransfer))"
            settlements.append("\(currentDebtor.name) paga \(formattedAmount) a \(currentCreditor.name)")

            updateRemainingBalances(debtor: &currentDebtor, creditor: &currentCreditor,
                                   amount: amountToTransfer, tempDebtors: &tempDebtors,
                                   tempCreditors: &tempCreditors)
        }

        if !tempDebtors.isEmpty || !tempCreditors.isEmpty {
            print("WARN: Quedaron saldos residuales después de la liquidación simple.")
        }

        return settlements.isEmpty ? ["¡Todas las cuentas están saldadas!"] : settlements
    }
    
    // MARK: - Private Helpers
    
    private func createCurrencyFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
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
        _ = expense.amount.rounded(toPlaces: 2)
        
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
                print("WARN: Gasto \(expense.expenseDescription) (Por Monto) - Suma detalles (\(calculatedSum)) != Monto total (\(expenseAmountRounded)). Usando detalles.")
            }
        } else {
            print("ERROR: Gasto \(expense.expenseDescription) (Por Monto) - Faltan detalles. Fallback a igual.")
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
            print("ERROR: Gasto \(expense.expenseDescription) (Por %) - Faltan detalles. Fallback a igual.")
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
                print("ERROR: Gasto \(expense.expenseDescription) (Por Partes) - Suma de partes es 0. Fallback a igual.")
                return calculateEqualShares(expense: expense, participants: participants)
            }
        } else {
            print("ERROR: Gasto \(expense.expenseDescription) (Por Partes) - Faltan detalles. Fallback a igual.")
            return calculateEqualShares(expense: expense, participants: participants)
        }
        
        return sharesToDebit
    }
}
