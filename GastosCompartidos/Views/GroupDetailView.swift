//
//  GroupDetailView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI
import SwiftData

struct GroupDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var group: Group // Usar @Bindable si modificas el grupo aquí
    @State private var viewModel = GroupDetailViewModel()
    @State private var showingAddExpenseSheet = false
    @State private var showingSettlements = false
    @State private var settlementsText: [String] = []
    @State private var showingAddMemberSheet = false // << NUEVO estado

    // Formateador para moneda
    private var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // Configurar localidad si es necesario
        // formatter.locale = Locale(identifier: "es_ES")
        // formatter.currencyCode = "EUR"
        return formatter
    }()

    // Inicializador explícito (opcional si Xcode no da problemas de acceso)
    internal init(group: Group) {
         self.group = group
    }

    var body: some View {
        List {
            // Sección Balances
            Section("Balances") {
                if viewModel.memberBalances.isEmpty {
                    Text("No hay miembros o gastos para calcular balances.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.memberBalances) { balanceInfo in
                        HStack {
                            Text(balanceInfo.name)
                            Spacer()
                            Text(balanceInfo.balance as NSNumber, formatter: currencyFormatter)
                                .foregroundStyle(balanceInfo.balance < -0.01 ? .red : (balanceInfo.balance > 0.01 ? .green : .primary))
                                .fontWeight(.medium)
                        }
                    }
                    if viewModel.memberBalances.contains(where: { abs($0.balance) > 0.01 }) {
                        Button {
                            settlementsText = viewModel.suggestSettlements()
                            showingSettlements = true
                        } label: {
                            Label("Sugerir Liquidaciones", systemImage: "arrow.right.arrow.left.circle")
                        }
                    }
                }
            }

            // Sección Miembros (Modificada)
            Section { // Quitamos el header explícito para que el botón y onDelete funcionen mejor
                ForEach(group.members ?? []) { member in
                    Text(member.name)
                }
                .onDelete(perform: removeMember) // << Habilitar borrado por deslizamiento

                // Botón para añadir miembros
                Button {
                    showingAddMemberSheet = true // << Mostrar hoja para añadir miembro
                } label: {
                    Label("Añadir Miembro", systemImage: "plus.circle.fill")
                }

            } header: { // Usar header para el título de sección
                Text("Miembros (\(group.members?.count ?? 0))")
            }

            // Sección Gastos
            Section("Gastos (\(group.expenses?.count ?? 0))") {
                 if group.expenses?.isEmpty ?? true {
                    Text("No hay gastos registrados.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(group.expenses?.sorted(by: { $0.date > $1.date }) ?? []) { expense in
                        ExpenseRowView(expense: expense, currencyFormatter: currencyFormatter)
                    }
                    .onDelete(perform: deleteExpense)
                }
            }
        }
        .navigationTitle(group.name)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Botón Editar para activar modo de borrado en listas
                EditButton() // << Añadido para modo edición (borrar miembros/gastos)

                // Botón para añadir un nuevo gasto
                Button { showingAddExpenseSheet = true } label: { Label("Añadir Gasto", systemImage: "plus") }
            }
        }
        // Hoja para añadir gastos
        .sheet(isPresented: $showingAddExpenseSheet) {
            AddExpenseView(group: group)
        }
        // << NUEVA Hoja Modal para Añadir Miembros >>
        .sheet(isPresented: $showingAddMemberSheet) {
             AddMemberView(group: group)
        }
        // Alerta para mostrar liquidaciones
        .alert("Liquidaciones Sugeridas", isPresented: $showingSettlements) {
            Button("OK") { }
        } message: {
            Text(settlementsText.joined(separator: "\n"))
        }
        // Tareas y Observadores
        .task {
            viewModel.calculateBalances(for: group)
        }
        .onChange(of: group.members) { _, _ in viewModel.calculateBalances(for: group) }
        .onChange(of: group.expenses) { _, _ in viewModel.calculateBalances(for: group) }
    }

    // Función para eliminar miembros (Nueva / Modificada)
    private func removeMember(offsets: IndexSet) {
        // Asegurarse de que group.members no sea nil y obtener la lista actual
        // Es importante obtener la lista ordenada como se muestra en la UI si el orden importa
        guard let currentMembers = group.members else { return }
        // Crear un array temporal basado en el orden actual si es necesario,
        // o asumir que el orden del ForEach coincide con el array subyacente.
        // Si no hay ordenación explícita en ForEach, podemos usar el array directamente.

        offsets.forEach { index in
             // Validar índice por si acaso
            if index < currentMembers.count {
                let memberToRemove = currentMembers[index]
                viewModel.removeMember(memberToRemove, from: group, context: modelContext)
            }
        }
    }

    // Función para eliminar gastos (sin cambios)
    private func deleteExpense(offsets: IndexSet) {
        guard let sortedExpenses = group.expenses?.sorted(by: { $0.date > $1.date }) else { return }
        offsets.forEach { index in
             if index < sortedExpenses.count { // Añadir validación de índice
                let expenseToDelete = sortedExpenses[index]
                viewModel.deleteExpense(expenseToDelete, context: modelContext)
            }
        }
    }
}

// --- Vista Auxiliar ExpenseRowView (sin cambios) ---
struct ExpenseRowView: View {
    let expense: Expense
    let currencyFormatter: NumberFormatter
    var body: some View {
         VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(expense.expenseDescription).font(.headline)
                Spacer()
                Text(expense.amount as NSNumber, formatter: currencyFormatter).font(.headline)
            }
            Text("Pagó: \(expense.payer?.name ?? "N/A")")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Participantes (\(expense.participants?.count ?? 0)): \(expense.participants?.map(\.name).joined(separator: ", ") ?? "N/A")")
                .font(.caption)
                .foregroundStyle(.tertiary)
            Text(expense.date, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

// --- Preview (Asegúrate de que siga funcionando) ---
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
        let person1 = Person(name: "Ana")
        let person2 = Person(name: "Juan")
        let group = Group(name: "Grupo Detalle Preview")
        group.members = [person1, person2]
        let expense1 = Expense(description: "Cena", amount: 50.0, date: Date(), payer: person1, participants: [person1, person2], group: group)
        let expense2 = Expense(description: "Taxi", amount: 20.0, date: Date().addingTimeInterval(-86400), payer: person2, participants: [person2], group: group)
        container.mainContext.insert(person1)
        container.mainContext.insert(person2)
        container.mainContext.insert(group)
        container.mainContext.insert(expense1)
        container.mainContext.insert(expense2)

        return NavigationStack {
            GroupDetailView(group: group)
        }
        .modelContainer(container)

    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
