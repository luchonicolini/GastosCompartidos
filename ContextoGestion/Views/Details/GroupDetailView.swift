//
//  GroupDetailView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//
// Views/GroupDetailView.swift



import SwiftUI
import SwiftData

struct GroupDetailView: View {
    @Bindable var group: Group
    @State private var viewModel = GroupDetailViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    // Sheet states
    @State private var showingAddExpenseSheet = false
    @State private var showingAddMemberSheet = false
    @State private var expenseToEdit: Expense?
    @State private var memberToEdit: Person?
    
    // Alert states
    @State private var showingDeleteExpenseAlert = false
    @State private var showingDeleteMemberAlert = false
    @State private var expenseToDelete: Expense?
    @State private var memberToDelete: Person?
    
    @Query private var expenses: [Expense]
    
    // Computed properties
    private var hasMembers: Bool {
        !(group.members?.isEmpty ?? true)
    }
    
    private var hasExpenses: Bool {
        !expenses.isEmpty
    }
    
    private var sortedMembers: [Person] {
        group.members?.sorted(by: { $0.name < $1.name }) ?? []
    }

    init(group: Group) {
        self.group = group
        let groupID = group.id
        let predicate = #Predicate<Expense> { $0.group?.id == groupID }
        _expenses = Query(filter: predicate, sort: [SortDescriptor(\Expense.date, order: .reverse)])
    }

    var body: some View {
        List {
            // MARK: - Summary Section
            summarySection
            
            // MARK: - Expenses Section
            expensesSection
            
            // MARK: - Members Section
            membersSection
        }
        .scrollContentBackground(.hidden)
        .background(Color("AppBackground"))
        .navigationTitle(group.name)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
        }
        .task {
            await setupViewModel()
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            AddExpenseView(
                onSave: {
                    Task { viewModel.calculateBalances(for: group) }
                },
                group: group
            )
        }
        .sheet(item: $expenseToEdit) { expense in
            AddExpenseView(
                onSave: {
                    Task { viewModel.calculateBalances(for: group) }
                },
                group: group,
                expenseToEdit: expense
            )
        }
        .sheet(isPresented: $showingAddMemberSheet) {
            AddMemberView(group: group, viewModel: viewModel)
        }
        .sheet(item: $memberToEdit) { member in
            EditMemberView(person: member, viewModel: viewModel)
        }
        .alert("Eliminar Gasto", isPresented: $showingDeleteExpenseAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let expense = expenseToDelete {
                    deleteExpense(expense)
                }
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar este gasto? Esta acción no se puede deshacer.")
        }
        .alert("Eliminar Miembro", isPresented: $showingDeleteMemberAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Eliminar", role: .destructive) {
                if let member = memberToDelete {
                    deleteMember(member)
                }
            }
        } message: {
            Text("¿Estás seguro de que quieres eliminar este miembro? Todos sus gastos asociados también se eliminarán.")
        }
        .onChange(of: group.expenses?.count) {
            Task { viewModel.calculateBalances(for: group) }
        }
        .onChange(of: group.members?.count) {
            Task { viewModel.calculateBalances(for: group) }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var summarySection: some View {
        Section("Resumen") {
            BalanceView(viewModel: viewModel)
               
            
            NavigationLink {
                SettlementView(viewModel: viewModel)
            } label: {
                Label("Ver Liquidaciones", systemImage: "arrow.right.arrow.left.circle.fill")
                    .foregroundStyle(.colorButton)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .disabled(!hasMembers || !hasExpenses)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private var expensesSection: some View {
        Section("Gastos (\(expenses.count))") {
            if hasExpenses {
                ForEach(expenses) { expense in
                    ExpenseRowView(expense: expense)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            expenseToEdit = expense
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                expenseToDelete = expense
                                showingDeleteExpenseAlert = true
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .transition(reduceMotion ? .opacity : .slide)
                }
            } else {
                EmptyStateView(
                    icon: "creditcard",
                    title: "No hay gastos",
                    description: hasMembers ? "¡Añade tu primer gasto!" : "Primero añade miembros al grupo"
                )
            }
            
            SectionActionButton(
                title: "Añadir Gasto",
                iconName: "plus.circle.fill",
                enabledColor: .colorButton,
                action: { showingAddExpenseSheet = true }
            )
            .disabled(!hasMembers)
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private var membersSection: some View {
        Section("Miembros (\(sortedMembers.count))") {
            if hasMembers {
                ForEach(sortedMembers) { member in
                    MemberRowView(member: member)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            memberToEdit = member
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                memberToDelete = member
                                showingDeleteMemberAlert = true
                            } label: {
                                Label("Eliminar", systemImage: "person.fill.xmark")
                            }
                        }
                        .transition(reduceMotion ? .opacity : .slide)
                }
            } else {
                EmptyStateView(
                    icon: "person.2",
                    title: "No hay miembros",
                    description: "Añade miembros para comenzar a dividir gastos"
                )
            }
            
            SectionActionButton(
                title: "Añadir Miembro",
                iconName: "person.badge.plus.fill",
                enabledColor: .colorButton,
                action: { showingAddMemberSheet = true }
            )
            .listRowSeparator(.hidden)
        }
    }
    
    @ViewBuilder
    private var backButton: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.backward")
                    .font(.headline.weight(.semibold))
                Text("Mis Grupos")
                    .font(.body)
            }
            .foregroundStyle(.blue)
        }
        .accessibilityLabel("Volver a Mis Grupos")
    }
    
    // MARK: - Actions
    
    @MainActor
    private func setupViewModel() async {
        viewModel.setGroup(group)
        viewModel.calculateBalances(for: group)
    }
    
    @MainActor
    private func deleteExpense(_ expense: Expense) {
        withAnimation(reduceMotion ? .none : .easeInOut) {
            viewModel.deleteExpense(expense, context: modelContext)
        }
        expenseToDelete = nil
    }
    
    @MainActor
    private func deleteMember(_ member: Person) {
        withAnimation(reduceMotion ? .none : .easeInOut) {
            viewModel.removeMember(member, from: group, context: modelContext)
        }
        memberToDelete = nil
    }
}

// MARK: - Supporting Views

struct SectionActionButton: View {
    let title: String
    let iconName: String
    let enabledColor: Color
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.headline.weight(.medium))
                Text(title)
                    .font(.headline.weight(.medium))
            }
            .foregroundColor(.white)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isEnabled ? enabledColor : Color.gray.opacity(0.5))
            )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .accessibilityLabel(title)
        .accessibilityHint(isEnabled ? "Toca para \(title.lowercased())" : "Deshabilitado")
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Preview

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
    
    let p1 = Person(name: "Frodo Bolsón")
    let p2 = Person(name: "Sam Gamyi")
    let group = Group(name: "Portadores del Anillo")
    group.members = [p1, p2]
    
    let expense1 = Expense(description: "Anillo Único", amount: 1000, payer: p1, participants: [p1, p2], group: group)
    let expense2 = Expense(description: "Cena en Bree", amount: 50, payer: p2, participants: [p1, p2], group: group)
    
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(group)
    container.mainContext.insert(expense1)
    container.mainContext.insert(expense2)

    return NavigationStack {
        GroupDetailView(group: group)
    }
    .modelContainer(container)
}
