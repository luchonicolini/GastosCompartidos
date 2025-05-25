//
//  AddExpenseViewModel.swift
//  GastosPrueba
//
//  Created by Luciano Nicolini on 16/04/2025.
//

import SwiftData
import Observation
import Foundation
import SwiftUI 

@Observable
class AddExpenseViewModel {

    var description: String = ""
    var amountString: String = ""
    var date: Date = Date()
    var selectedPayerId: UUID?
    var selectedParticipantIds: Set<UUID> = []

    private var expenseToEdit: Expense?
    private var groupMembers: [Person] = []

    var selectedSplitType: SplitType = .equally {
        didSet {
            if oldValue != selectedSplitType {
                splitInputValues = [:]
                 // No limpiar errores aquí, la validación lo hará al guardar
            }
        }
    }
    var splitInputValues: [UUID: String] = [:]

    func setup(expense: Expense? = nil, members: [Person]) {
        self.expenseToEdit = expense
        self.groupMembers = members
        self.splitInputValues = [:]

        if let expense = expense {
            description = expense.expenseDescription
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
            formatter.usesGroupingSeparator = false // Important for plain number strings
            formatter.decimalSeparator = "." // To ensure consistency with previous behavior and typical parsing expectations if locale is not US.
            amountString = formatter.string(from: NSNumber(value: expense.amount)) ?? ""
            date = expense.date
            selectedPayerId = expense.payer?.id
            selectedParticipantIds = Set(expense.participants?.map { $0.id } ?? [])
            selectedSplitType = expense.splitType

            if expense.splitType != .equally, let details = expense.splitDetails {
                let formatter = NumberFormatter()
                formatter.numberStyle = .decimal
                formatter.minimumFractionDigits = 0
                formatter.maximumFractionDigits = 2

                splitInputValues = details.mapValues { value in
                    formatter.string(from: NSNumber(value: value)) ?? ""
                }
            }
        } else {
            clearForm()
        }
    }

    func availableMembers() -> [Person] { return groupMembers }

    func clearForm() {
        description = ""
        amountString = ""
        date = Date()
        selectedPayerId = nil
        selectedParticipantIds = []
        selectedSplitType = .equally
        splitInputValues = [:]
        
    }

    @MainActor
     func saveExpense(for group: Group, context: ModelContext) throws {
         // Validar descripción y monto
         try validateExpenseBasics()
         
         // Convertir y validar el monto
         let totalAmount = try validateAndConvertAmount()
         
         // Validar participantes
         let (payer, participants) = try validateParticipants()
         
         // Validar y preparar detalles de división
         let splitDetailsDict = try validateAndPrepareSplitDetails(totalAmount: totalAmount, participants: participants)
                 
         // Guardar el gasto
         try saveExpenseToDatabase(
             group: group,
             context: context,
             description: description.trimmingCharacters(in: .whitespacesAndNewlines),
             amount: totalAmount,
             payer: payer,
             participants: participants,
             splitDetailsDict: splitDetailsDict
         )
     }
     
     // MARK: - Private Helper Methods
     
     private func validateExpenseBasics() throws {
         let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
         guard !trimmedDescription.isEmpty else {
             throw ExpenseError.emptyDescription
         }
     }
     
     private func validateAndConvertAmount() throws -> Double {
         let trimmedAmountString = amountString.trimmingCharacters(in: .whitespaces)
         let formatter = NumberFormatter()
         formatter.numberStyle = .decimal
         
         guard let totalAmountNumber = formatter.number(from: trimmedAmountString) else {
             throw ExpenseError.invalidAmountFormat
         }
         
         let totalAmount = totalAmountNumber.doubleValue.rounded(toPlaces: 2)
         guard totalAmount > 0 else {
             throw ExpenseError.nonPositiveAmount
         }
         
         return totalAmount
     }
     
     private func validateParticipants() throws -> (Person, [Person]) {
         guard let payerId = selectedPayerId,
               let payer = groupMembers.first(where: { $0.id == payerId }) else {
             throw ExpenseError.noPayerSelected
         }
         
         let participants = groupMembers.filter { selectedParticipantIds.contains($0.id) }
         guard !participants.isEmpty else {
             throw ExpenseError.noParticipantsSelected
         }
         
         return (payer, participants)
     }
     
     private func validateAndPrepareSplitDetails(totalAmount: Double, participants: [Person]) throws -> [UUID: Double]? {
         // Si la división es equitativa, no necesitamos detalles específicos
         if selectedSplitType == .equally {
             return nil
         }
         
         var detailsDict: [UUID: Double] = [:]
         var inputSum: Double = 0.0
         let formatter = NumberFormatter()
         formatter.numberStyle = .decimal
         
         // Validar y recoger todos los valores de entrada
         for personId in selectedParticipantIds {
             guard let inputString = splitInputValues[personId]?.trimmingCharacters(in: .whitespaces),
                   !inputString.isEmpty,
                   let individualNumber = formatter.number(from: inputString)
             else {
                 let name = groupMembers.first { $0.id == personId }?.name ?? "ID \(personId.uuidString.prefix(4))..."
                 throw ExpenseError.splitInputMissingOrInvalid(name)
             }

             let doubleValue = individualNumber.doubleValue

             // Validar valor según tipo de división
             switch selectedSplitType {
             case .byShares:
                 if doubleValue <= 0 {
                     throw ExpenseError.splitSharesSumInvalid
                 }
             case .byAmount, .byPercentage:
                 if doubleValue < 0 {
                     throw ExpenseError.nonPositiveAmount
                 }
             case .equally:
                 break // No debería llegar aquí
             }

             detailsDict[personId] = doubleValue
             inputSum += doubleValue
         }

         inputSum = inputSum.rounded(toPlaces: 2) // Redondear suma para comparación

         // Validar suma de valores según tipo de división
         switch selectedSplitType {
         case .byAmount:
             if abs(inputSum - totalAmount) > 0.01 {
                  throw ExpenseError.splitAmountSumMismatch(inputSum, totalAmount)
             }
         case .byPercentage:
             if abs(inputSum - 100.0) > 0.01 {
                 throw ExpenseError.splitPercentageSumMismatch(inputSum)
             }
         case .byShares:
             if inputSum <= 0 {
                  throw ExpenseError.splitSharesSumInvalid
             }
         case .equally:
             break // No debería llegar aquí
         }
         
         return detailsDict
     }
     
     @MainActor
     private func saveExpenseToDatabase(
         group: Group,
         context: ModelContext,
         description: String,
         amount: Double,
         payer: Person,
         participants: [Person],
         splitDetailsDict: [UUID: Double]?
     ) throws {
         do {
             if let expense = expenseToEdit {
                 try updateExistingExpense( // Mark with try
                     expense: expense,
                     description: description,
                     amount: amount,
                     payer: payer,
                     participants: participants,
                     splitDetailsDict: splitDetailsDict
                 )
             } else {
                 try createNewExpense( // Mark with try
                     context: context,
                     description: description,
                     amount: amount,
                     payer: payer,
                     participants: participants,
                     group: group,
                     splitDetailsDict: splitDetailsDict
                 )
             }
             
             try context.save()
         } catch let specificError as ExpenseError { // If it's already an ExpenseError
             throw specificError // Rethrow it as is
         } catch { // For other errors (like context.save() errors)
             print("Database Save/Update Error on saveExpense: \(error.localizedDescription)")
             throw ExpenseError.databaseSaveError(error)
         }
     }
     
     private func updateExistingExpense(
         expense: Expense,
         description: String,
         amount: Double,
         payer: Person,
         participants: [Person],
         splitDetailsDict: [UUID: Double]?
     ) throws { // Add throws
        expense.expenseDescription = description
        expense.amount = amount
        expense.date = date
        expense.payer = payer
        expense.participants = participants
        expense.splitType = selectedSplitType
        do {
            try expense.splitDetails = splitDetailsDict
        } catch let error as ExpenseError { // Catch specific ExpenseError
            throw error // Re-throw the caught ExpenseError
        } catch {
            // Handle other potential errors if necessary, or just rethrow
            throw error 
        }
     }
     
     private func createNewExpense(
         context: ModelContext,
         description: String,
         amount: Double,
         payer: Person,
         participants: [Person],
         group: Group,
         splitDetailsDict: [UUID: Double]?
     ) throws { // Add throws
        let newExpense: Expense
        do {
            newExpense = try Expense( // Add try
                description: description,
                amount: amount,
             date: date,
             payer: payer,
             participants: participants,
             group: group,
             splitType: selectedSplitType,
             splitDetails: splitDetailsDict
            )
        } catch let error as ExpenseError { // Catch specific ExpenseError
            throw error // Re-throw the caught ExpenseError
        } catch {
            throw error 
        }
        context.insert(newExpense)
     }
 }
