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
    @State private var showingAddExpenseSheet = false
    @State private var showingAddMemberSheet = false
    @State private var expenseToEdit: Expense?
    @State private var memberToEdit: Person?

    @Query private var expenses: [Expense]

    init(group: Group) {
        self.group = group
        let groupID = group.id
        let predicate = #Predicate<Expense> { $0.group?.id == groupID }
        _expenses = Query(filter: predicate, sort: [SortDescriptor(\Expense.date, order: .reverse)])
    }

    var body: some View {
        List {
            Section("Resumen") {
                BalanceView(viewModel: viewModel)
                NavigationLink {
                    SettlementView(viewModel: viewModel)
                } label: {
                    Label("Ver Liquidaciones", systemImage: "arrow.right.arrow.left.circle.fill")
                }
            }

            Section("Gastos") {
                if expenses.isEmpty {
                    Text("No hay gastos todavía. ¡Añade uno!")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(expenses) { expense in
                        ExpenseRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                expenseToEdit = expense
                            }
                    }
                    .onDelete(perform: deleteExpense)
                }
                // Nuevo botón "Añadir Gasto" aquí
                SectionActionButton(
                    title: "Añadir Gasto",
                    iconName: "plus.circle.fill",
                    enabledColor: .blue, // O tu color de acento principal
                    action: { showingAddExpenseSheet = true }
                )
                .disabled(group.members?.isEmpty ?? true) // Mantener la lógica de deshabilitación
                .listRowSeparator(.hidden) // Ocultar el separador de fila de lista para el botón
            }

            Section("Miembros") {
                if let members = group.members?.sorted(by: { $0.name < $1.name }), !members.isEmpty {
                    ForEach(members) { member in
                         MemberRowView(member: member) // Usando tu MemberRowView
                            .contentShape(Rectangle())
                            .onTapGesture {
                                 memberToEdit = member
                            }
                    }
                    .onDelete(perform: deleteMember)
                } else {
                    Text("No hay miembros en este grupo.")
                        .foregroundStyle(.secondary)
                }
                // Nuevo botón "Añadir Miembro" aquí
                SectionActionButton(
                    title: "Añadir Miembro",
                    iconName: "person.badge.plus.fill", // Icono diferente para variar
                    enabledColor: .blue, // O tu color de acento principal
                    action: { showingAddMemberSheet = true }
                )
                .listRowSeparator(.hidden) // Ocultar el separador de fila de lista para el botón
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("AppBackground"))
        .navigationTitle(group.name)

        .task {
            viewModel.setGroup(group)
        }
        .sheet(isPresented: $showingAddExpenseSheet) {
            // Asumo que tienes tu AddExpenseView aquí
             AddExpenseView(onSave: { viewModel.calculateBalances(for: group) }, group: group)
        }
        .sheet(item: $expenseToEdit) { expense in
             AddExpenseView(onSave: { viewModel.calculateBalances(for: group) }, group: group, expenseToEdit: expense)
        }
        .sheet(isPresented: $showingAddMemberSheet) {
            AddMemberView(group: group, viewModel: viewModel)
        }
        .sheet(item: $memberToEdit) { member in
             EditMemberView(person: member, viewModel: viewModel)
        }
        .onChange(of: group.expenses?.count) { viewModel.calculateBalances(for: group) }
        .onChange(of: group.members?.count) { viewModel.calculateBalances(for: group) }
    }

    @MainActor private func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { index in
            if index < expenses.count {
                 let expenseToDelete = expenses[index]
                 viewModel.deleteExpense(expenseToDelete, context: modelContext)
            }
        }
    }

    @MainActor private func deleteMember(at offsets: IndexSet) {
         if let members = group.members?.sorted(by: { $0.name < $1.name }) {
              offsets.forEach { index in
                   if index < members.count {
                        let memberToDelete = members[index]
                        viewModel.removeMember(memberToDelete, from: group, context: modelContext)
                   }
              }
         }
    }
}

// No olvides el Preview de GroupDetailView si lo tienes, para probar estos cambios.
#Preview {
    // Configuración del Preview...
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
    let p1 = Person(name: "Frodo Bolsón")
    let p2 = Person(name: "Sam Gamyi")
    let group = Group(name: "Portadores del Anillo")
    group.members = [p1, p2]
    let expense1 = Expense(description: "Anillo Único", amount: 1000, payer: p1, participants: [p1, p2], group: group)
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(group)
    container.mainContext.insert(expense1)

    return NavigationStack {
        GroupDetailView(group: group)
    }
    .modelContainer(container)
}





struct SectionActionButton: View {
    let title: String
    let iconName: String
    let enabledColor: Color // Color cuando el botón está habilitado
    let action: () -> Void

    @Environment(\.isEnabled) private var isEnabled // Para detectar el estado de habilitación

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.white) // Texto e icono en blanco
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity) // Para que ocupe el ancho disponible
            .background(isEnabled ? enabledColor : Color.gray.opacity(0.5)) // Color dinámico
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        // El .disabled() se aplicará desde la vista que lo usa
        // Se ajustan los insets para que se vea bien dentro de una List
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    }
}
