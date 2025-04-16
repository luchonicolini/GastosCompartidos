//
//  GroupDetailView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI
import SwiftData


struct GroupDetailView: View {
    // MARK: - Environment & State Variables
    @Environment(\.modelContext) private var modelContext
    @Bindable var group: Group // Enlace bidireccional al grupo
    @State private var viewModel = GroupDetailViewModel() // ViewModel para lógica

    // Estados para presentar Hojas Modales (Sheets)
    @State private var showingAddExpenseSheet = false
    @State private var showingAddMemberSheet = false
    @State private var expenseToEdit: Expense? = nil // Para editar gasto existente

    // Estados para Alertas
    @State private var showingSettlements = false
    @State private var settlementsText: [String] = []
    @State private var showingRenameGroupAlert = false
    @State private var showingRenamePersonAlert = false

    // Estados para edición de nombres
    @State private var newGroupName: String = "" // Temporal para renombrar grupo
    @State private var personToRename: Person? = nil // Temporal para saber qué persona renombrar
    @State private var newPersonName: String = "" // Temporal para renombrar persona

    // MARK: - Formateador
    private var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        // formatter.locale = Locale.current // Opcional: especificar locale
        // formatter.currencyCode = "USD" // Opcional: especificar código moneda
        return formatter
    }()

    // MARK: - Inicializador
    internal init(group: Group) {
         self.group = group
         // Nota: @State / @StateObject se inicializan antes que esto.
         // Cargar el nombre actual para la alerta se hace al tocar el botón.
    }

    // MARK: - Body
    var body: some View {
        List {
            // MARK: Section: Balances
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
                    // Botón para sugerir liquidaciones
                    if viewModel.memberBalances.contains(where: { abs($0.balance) > 0.01 }) {
                        Button {
                            settlementsText = viewModel.suggestSettlements()
                            showingSettlements = true
                        } label: {
                            Label("Sugerir Liquidaciones", systemImage: "arrow.right.arrow.left.circle")
                        }
                    }
                }
            } // Fin Section Balances

            // MARK: Section: Miembros
            Section {
                // Lista de miembros ordenados, con acción de tap para renombrar
                ForEach(group.members?.sorted(by: { $0.name < $1.name }) ?? []) { member in
                    Text(member.name)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle()) // Área tappable completa
                        .onTapGesture {
                            // Acción al tocar un miembro: preparar para renombrar
                            personToRename = member
                            newPersonName = member.name // Cargar nombre actual
                            showingRenamePersonAlert = true // Activar alerta
                        }
                }
                .onDelete(perform: removeMember) // Acción de borrar miembro

                // Botón para añadir miembro
                Button {
                    showingAddMemberSheet = true
                } label: {
                    Label("Añadir Miembro", systemImage: "plus.circle.fill")
                }

            } header: {
                // Título de la sección de miembros
                Text("Miembros (\(group.members?.count ?? 0))")
            } // Fin Section Miembros

            // MARK: Section: Gastos
            Section("Gastos (\(group.expenses?.count ?? 0))") {
                 if group.expenses?.isEmpty ?? true {
                    Text("No hay gastos registrados.")
                        .foregroundStyle(.secondary)
                } else {
                    // Lista de gastos ordenados por fecha, con acción de tap para editar
                    ForEach(group.expenses?.sorted(by: { $0.date > $1.date }) ?? []) { expense in
                        // Contenido de la fila del gasto
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
                        .contentShape(Rectangle()) // Área tappable completa
                        .onTapGesture {
                            // Acción al tocar un gasto: preparar para editar
                            expenseToEdit = expense // Activa la hoja de edición
                        }
                    }
                    .onDelete(perform: deleteExpense) // Acción de borrar gasto
                }
            } // Fin Section Gastos
        } // --- Fin del List ---

        // MARK: Modificadores de Vista
        .navigationTitle(group.name) // Título que se actualiza si cambia el nombre del grupo
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // Botón para activar/desactivar modo edición de listas (borrar)
                EditButton()

                // Botón para Renombrar Grupo
                Button {
                    newGroupName = group.name // Cargar nombre actual
                    showingRenameGroupAlert = true // Mostrar alerta
                } label: {
                    Label("Renombrar Grupo", systemImage: "pencil")
                }

                // Botón para Añadir Gasto
                Button { showingAddExpenseSheet = true } label: { Label("Añadir Gasto", systemImage: "plus") }
            }
        }
        // --- Hojas Modales (.sheet) ---
        .sheet(isPresented: $showingAddExpenseSheet) {
             // Presenta vista para añadir gasto (sin pasar expenseToEdit)
            AddExpenseView(group: group, expenseToEdit: nil)
        }
        .sheet(item: $expenseToEdit) { expense in
             // Presenta vista para editar gasto (pasando el expense)
            AddExpenseView(group: group, expenseToEdit: expense)
        }
        .sheet(isPresented: $showingAddMemberSheet) {
             // Presenta vista para añadir miembro
             AddMemberView(group: group)
        }
        // --- Alertas (.alert) ---
        .alert("Liquidaciones Sugeridas", isPresented: $showingSettlements) {
             Button("OK") { } // Botón simple para cerrar
        } message: {
            Text(settlementsText.joined(separator: "\n")) // Muestra las sugerencias
        }
        .alert("Renombrar Grupo", isPresented: $showingRenameGroupAlert) {
            // Alerta para renombrar el grupo
            TextField("Nuevo nombre del grupo", text: $newGroupName)
                .autocorrectionDisabled()

            Button("Guardar") {
                let trimmedName = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    print("Renombrando grupo '\(group.name)' a '\(trimmedName)'")
                    group.name = trimmedName // Actualiza el nombre directamente
                }
            }
            Button("Cancelar", role: .cancel) { } // Botón para cancelar

        } message: {
             Text("Introduce el nuevo nombre para el grupo '\(group.name)'.") // Mensaje informativo
        }
        .alert("Renombrar Persona", isPresented: $showingRenamePersonAlert, presenting: personToRename) { person in
            // Alerta para renombrar persona (usando 'presenting' para pasar la persona)
            TextField("Nuevo nombre", text: $newPersonName)
                .autocorrectionDisabled()

            Button("Guardar") {
                let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty && trimmedName != person.name {
                    print("Renombrando persona '\(person.name)' a '\(trimmedName)'")
                    person.name = trimmedName // Actualiza el nombre de la persona globalmente
                }
                resetRenamePersonStates() // Limpiar estados después de acción
            }
            Button("Cancelar", role: .cancel) {
                resetRenamePersonStates() // Limpiar estados al cancelar
            }
        } message: { person in
            // Mensaje informativo
            Text("Introduce el nuevo nombre para '\(person.name)'. Este cambio se reflejará en todos los grupos.")
        }

        // --- Tareas y Observadores de Cambios ---
        .task {
            // Calcular balances al cargar la vista
            viewModel.calculateBalances(for: group)
        }
        .onChange(of: group.members) { _, _ in
             // Recalcular balances si cambian los miembros
            viewModel.calculateBalances(for: group)
        }
        .onChange(of: group.expenses) { _, _ in
             // Recalcular balances si cambian los gastos
            viewModel.calculateBalances(for: group)
        }

    } // --- Fin del body ---

    // MARK: - Funciones Auxiliares
    private func resetRenamePersonStates() {
        // Limpia las variables de estado usadas para renombrar persona
        personToRename = nil
        newPersonName = ""
        showingRenamePersonAlert = false
    }

    private func removeMember(offsets: IndexSet) {
        // Lógica para eliminar miembros de la relación del grupo
        guard let currentMembers = group.members?.sorted(by: { $0.name < $1.name }) else { return } // Asegurar el mismo orden que ForEach
        offsets.forEach { index in
            if index < currentMembers.count {
                let memberToRemove = currentMembers[index]
                viewModel.removeMember(memberToRemove, from: group, context: modelContext)
            }
        }
    }

    private func deleteExpense(offsets: IndexSet) {
        // Lógica para eliminar gastos del contexto
        guard let sortedExpenses = group.expenses?.sorted(by: { $0.date > $1.date }) else { return }
        offsets.forEach { index in
            if index < sortedExpenses.count {
                let expenseToDelete = sortedExpenses[index]
                viewModel.deleteExpense(expenseToDelete, context: modelContext)
            }
        }
    }
} // --- Fin de la struct GroupDetailView ---

// MARK: - Preview
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
        // --- Crear datos de ejemplo para el preview ---
        let person1 = Person(name: "Ana")
        let person2 = Person(name: "Juan")
        let group = Group(name: "Grupo Detalle Preview")
        group.members = [person1, person2]
        let expense1 = Expense(description: "Cena", amount: 50.0, date: Date(), payer: person1, participants: [person1, person2], group: group)
        // Insertar datos en el contexto del preview
        container.mainContext.insert(person1)
        container.mainContext.insert(person2)
        container.mainContext.insert(group)
        container.mainContext.insert(expense1)

        // Devolver la vista dentro de un NavigationStack para que se vea el título/toolbar
        return NavigationStack {
            GroupDetailView(group: group)
        }
        .modelContainer(container) // Aplicar el contenedor al preview

    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
