//
//  ExpenseModelViewModelTests.swift
//  ContextoGestionTests
//
//  Created by AI Worker on [Current Date]
//

import XCTest
import SwiftData
@testable import ContextoGestion

class ExpenseModelViewModelTests: XCTestCase {

    var modelContext: ModelContext!

    @MainActor
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create an in-memory SwiftData store
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Expense.self, Person.self, Group.self, configurations: config)
        modelContext = ModelContext(container)
    }

    override func tearDownWithError() throws {
        modelContext = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods
    @MainActor
    private func createPerson(name: String) -> Person {
        let person = Person(name: name, email: "\(name)@example.com")
        modelContext.insert(person)
        return person
    }

    @MainActor
    private func createGroup(name: String, members: [Person]) -> Group {
        let group = Group(name: name, creationDate: Date(), members: members)
        modelContext.insert(group)
        try? modelContext.save() // Save group to establish relationships
        return group
    }

    // MARK: - AddExpenseViewModel Tests

    @MainActor
    func testAddExpense_EquallySplit_SavesCorrectly() throws {
        let viewModel = AddExpenseViewModel()
        
        let payer = createPerson(name: "Payer Alice")
        let participant1 = createPerson(name: "Participant Bob")
        let participant2 = createPerson(name: "Participant Charles")
        let members = [payer, participant1, participant2]
        let group = createGroup(name: "Test Group Equally", members: members)

        viewModel.setup(members: members)
        viewModel.description = "Dinner"
        viewModel.amountString = "90.00"
        viewModel.date = Date()
        viewModel.selectedPayerId = payer.id
        viewModel.selectedParticipantIds = [participant1.id, participant2.id]
        viewModel.selectedSplitType = .equally

        try viewModel.saveExpense(for: group, context: modelContext)

        // Fetch the expense to verify
        let fetchDescriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.expenseDescription == "Dinner" })
        let expenses = try modelContext.fetch(fetchDescriptor)
        let savedExpense = try XCTUnwrap(expenses.first, "Expense should be saved")

        XCTAssertEqual(savedExpense.expenseDescription, "Dinner")
        XCTAssertEqual(savedExpense.amount, 90.00)
        XCTAssertEqual(savedExpense.payer?.id, payer.id)
        XCTAssertEqual(savedExpense.participants?.count, 2)
        XCTAssertEqual(savedExpense.splitType, .equally)
        XCTAssertNil(savedExpense.splitDetails, "SplitDetails should be nil for equally split")
    }

    @MainActor
    func testAddExpense_ByAmountSplit_SavesCorrectly() throws {
        let viewModel = AddExpenseViewModel()

        let payer = createPerson(name: "Payer David")
        let participant1 = createPerson(name: "Participant Eve")
        let participant2 = createPerson(name: "Participant Frank")
        let members = [payer, participant1, participant2]
        let group = createGroup(name: "Test Group ByAmount", members: members)

        viewModel.setup(members: members)
        viewModel.description = "Groceries"
        viewModel.amountString = "100.00"
        viewModel.date = Date()
        viewModel.selectedPayerId = payer.id
        viewModel.selectedParticipantIds = [participant1.id, participant2.id]
        viewModel.selectedSplitType = .byAmount
        viewModel.splitInputValues = [
            participant1.id: "40.00",
            participant2.id: "60.00"
        ]

        try viewModel.saveExpense(for: group, context: modelContext)

        let fetchDescriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.expenseDescription == "Groceries" })
        let expenses = try modelContext.fetch(fetchDescriptor)
        let savedExpense = try XCTUnwrap(expenses.first)

        XCTAssertEqual(savedExpense.amount, 100.00)
        XCTAssertEqual(savedExpense.splitType, .byAmount)
        let details = try XCTUnwrap(savedExpense.splitDetails)
        XCTAssertEqual(details[participant1.id], 40.00)
        XCTAssertEqual(details[participant2.id], 60.00)
    }

    @MainActor
    func testAddExpense_ByPercentageSplit_SavesCorrectly() throws {
        let viewModel = AddExpenseViewModel()

        let payer = createPerson(name: "Payer Grace")
        let participant1 = createPerson(name: "Participant Heidi")
        let participant2 = createPerson(name: "Participant Ivan")
        let members = [payer, participant1, participant2]
        let group = createGroup(name: "Test Group ByPercentage", members: members)

        viewModel.setup(members: members)
        viewModel.description = "Tickets"
        viewModel.amountString = "200.00"
        viewModel.date = Date()
        viewModel.selectedPayerId = payer.id
        viewModel.selectedParticipantIds = [participant1.id, participant2.id]
        viewModel.selectedSplitType = .byPercentage
        viewModel.splitInputValues = [
            participant1.id: "30", // 30%
            participant2.id: "70"  // 70%
        ]

        try viewModel.saveExpense(for: group, context: modelContext)

        let fetchDescriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.expenseDescription == "Tickets" })
        let expenses = try modelContext.fetch(fetchDescriptor)
        let savedExpense = try XCTUnwrap(expenses.first)

        XCTAssertEqual(savedExpense.amount, 200.00)
        XCTAssertEqual(savedExpense.splitType, .byPercentage)
        let details = try XCTUnwrap(savedExpense.splitDetails)
        XCTAssertEqual(details[participant1.id], 30.0)
        XCTAssertEqual(details[participant2.id], 70.0)
    }
    
    @MainActor
    func testAddExpense_BySharesSplit_SavesCorrectly() throws {
        let viewModel = AddExpenseViewModel()

        let payer = createPerson(name: "Payer Judy")
        let participant1 = createPerson(name: "Participant Kevin")
        let participant2 = createPerson(name: "Participant Liam")
        let members = [payer, participant1, participant2]
        let group = createGroup(name: "Test Group ByShares", members: members)

        viewModel.setup(members: members)
        viewModel.description = "Shared Software"
        viewModel.amountString = "150.00" // Total amount, split by shares will refer to this
        viewModel.date = Date()
        viewModel.selectedPayerId = payer.id
        viewModel.selectedParticipantIds = [participant1.id, participant2.id]
        viewModel.selectedSplitType = .byShares
        viewModel.splitInputValues = [
            participant1.id: "1", // 1 share
            participant2.id: "2"  // 2 shares
        ]

        try viewModel.saveExpense(for: group, context: modelContext)

        let fetchDescriptor = FetchDescriptor<Expense>(predicate: #Predicate { $0.expenseDescription == "Shared Software" })
        let expenses = try modelContext.fetch(fetchDescriptor)
        let savedExpense = try XCTUnwrap(expenses.first)

        XCTAssertEqual(savedExpense.amount, 150.00)
        XCTAssertEqual(savedExpense.splitType, .byShares)
        let details = try XCTUnwrap(savedExpense.splitDetails)
        XCTAssertEqual(details[participant1.id], 1.0) // Shares are stored directly
        XCTAssertEqual(details[participant2.id], 2.0)
    }


    // MARK: - GroupDetailViewModel Tests
    @MainActor
    func testGroupDetailViewModel_BalanceCalculation_WithByAmountSplit_PayerIsNotParticipantInSplit() throws {
        let currencyFormatter = NumberFormatter.createCurrencyFormatter(for: Locale(identifier: "es_AR"))
        let viewModel = GroupDetailViewModel(modelContext: modelContext, currencyFormatter: currencyFormatter)

        let payer = createPerson(name: "Payer BalTest PayerOnly")
        let participant1 = createPerson(name: "Participant Bal1 ByAmount")
        let participant2 = createPerson(name: "Participant Bal2 ByAmount")
        let nonParticipantMember = createPerson(name: "NonParticipant Member")

        let members = [payer, participant1, participant2, nonParticipantMember]
        let group = createGroup(name: "Balance Test Group ByAmount", members: members)
        
        let expenseAmount = 100.00
        let splitDetailsDict: [UUID: Double] = [
            participant1.id: 40.00,
            participant2.id: 60.00 
        ]

        let expense = Expense(
            description: "ByAmount Expense",
            amount: expenseAmount,
            date: Date(),
            payer: payer, // Payer pays 100
            participants: [participant1, participant2], // These two share the cost
            group: group,
            splitType: .byAmount,
            splitDetails: splitDetailsDict
        )
        modelContext.insert(expense)
        group.expenses?.append(expense)
        try modelContext.save()

        viewModel.setGroup(group)

        // Payer: Paid 100, their share is 0 (not in splitDetails). Balance = +100.
        let payerBalance = viewModel.memberBalances.first { $0.member.id == payer.id }
        XCTAssertEqual(payerBalance?.balance, 100.00, accuracy: 0.01, "Payer's balance incorrect")

        // Participant1: Owes 40. Balance = -40.
        let p1Balance = viewModel.memberBalances.first { $0.member.id == participant1.id }
        XCTAssertEqual(p1Balance?.balance, -40.00, accuracy: 0.01, "Participant1's balance incorrect")

        // Participant2: Owes 60. Balance = -60.
        let p2Balance = viewModel.memberBalances.first { $0.member.id == participant2.id }
        XCTAssertEqual(p2Balance?.balance, -60.00, accuracy: 0.01, "Participant2's balance incorrect")
        
        // NonParticipantMember: Not involved. Balance = 0.
        let nonPBalance = viewModel.memberBalances.first { $0.member.id == nonParticipantMember.id }
        XCTAssertEqual(nonPBalance?.balance, 0.00, accuracy: 0.01, "NonParticipant's balance incorrect")
    }
    
    @MainActor
    func testGroupDetailViewModel_BalanceCalculation_EquallySplit_PayerIsParticipant() throws {
        let currencyFormatter = NumberFormatter.createCurrencyFormatter(for: Locale(identifier: "es_AR"))
        let viewModel = GroupDetailViewModel(modelContext: modelContext, currencyFormatter: currencyFormatter)

        let member1 = createPerson(name: "M1 EqualPay") // Payer and Participant
        let member2 = createPerson(name: "M2 EqualPay") // Participant
        let member3 = createPerson(name: "M3 EqualPay") // Participant

        let members = [member1, member2, member3]
        let group = createGroup(name: "Equal Split Payer Participant Group", members: members)

        let expenseAmount = 90.00
        // All 3 participants share equally, so 30 each.
        let expense = Expense(
            description: "Lunch Equally",
            amount: expenseAmount,
            date: Date(),
            payer: member1, // Member1 pays 90
            participants: [member1, member2, member3], 
            group: group,
            splitType: .equally,
            splitDetails: nil
        )
        modelContext.insert(expense)
        group.expenses?.append(expense)
        try modelContext.save()

        viewModel.setGroup(group)
        
        // Member1: Paid 90, share is 30. Balance = 90 - 30 = +60
        let m1Balance = viewModel.memberBalances.first { $0.member.id == member1.id }
        XCTAssertEqual(m1Balance?.balance, 60.00, accuracy: 0.01, "Member1's balance incorrect")

        // Member2: Paid 0, share is 30. Balance = 0 - 30 = -30
        let m2Balance = viewModel.memberBalances.first { $0.member.id == member2.id }
        XCTAssertEqual(m2Balance?.balance, -30.00, accuracy: 0.01, "Member2's balance incorrect")

        // Member3: Paid 0, share is 30. Balance = 0 - 30 = -30
        let m3Balance = viewModel.memberBalances.first { $0.member.id == member3.id }
        XCTAssertEqual(m3Balance?.balance, -30.00, accuracy: 0.01, "Member3's balance incorrect")
    }

    @MainActor
    func testGroupDetailViewModel_BalanceCalculation_BySharesSplit_PayerIsParticipant() throws {
        let currencyFormatter = NumberFormatter.createCurrencyFormatter(for: Locale(identifier: "es_AR"))
        let viewModel = GroupDetailViewModel(modelContext: modelContext, currencyFormatter: currencyFormatter)

        let member1 = createPerson(name: "M1 SharesPay") // Payer and Participant (1 share)
        let member2 = createPerson(name: "M2 SharesPay") // Participant (2 shares)
        let member3 = createPerson(name: "M3 SharesPay") // Participant (3 shares)
        // Total shares = 1 + 2 + 3 = 6

        let members = [member1, member2, member3]
        let group = createGroup(name: "ByShares Payer Participant Group", members: members)

        let expenseAmount = 120.00 // Amount per share = 120 / 6 = 20
        let splitDetailsDict: [UUID: Double] = [
            member1.id: 1, // 1 share
            member2.id: 2, // 2 shares
            member3.id: 3  // 3 shares
        ]
        
        let expense = Expense(
            description: "Project ByShares",
            amount: expenseAmount,
            date: Date(),
            payer: member1, // Member1 pays 120
            participants: [member1, member2, member3], 
            group: group,
            splitType: .byShares,
            splitDetails: splitDetailsDict
        )
        modelContext.insert(expense)
        group.expenses?.append(expense)
        try modelContext.save()

        viewModel.setGroup(group)
        
        // Member1: Paid 120. Share value = (120/6)*1 = 20. Balance = 120 - 20 = +100
        let m1Balance = viewModel.memberBalances.first { $0.member.id == member1.id }
        XCTAssertEqual(m1Balance?.balance, 100.00, accuracy: 0.01, "Member1's balance incorrect")

        // Member2: Paid 0. Share value = (120/6)*2 = 40. Balance = 0 - 40 = -40
        let m2Balance = viewModel.memberBalances.first { $0.member.id == member2.id }
        XCTAssertEqual(m2Balance?.balance, -40.00, accuracy: 0.01, "Member2's balance incorrect")

        // Member3: Paid 0. Share value = (120/6)*3 = 60. Balance = 0 - 60 = -60
        let m3Balance = viewModel.memberBalances.first { $0.member.id == member3.id }
        XCTAssertEqual(m3Balance?.balance, -60.00, accuracy: 0.01, "Member3's balance incorrect")
    }
}
