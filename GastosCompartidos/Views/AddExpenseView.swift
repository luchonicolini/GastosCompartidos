//
//  AddExpenseView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    let group: Group
    var expenseToEdit: Expense?

    @State private var viewModel = AddExpenseViewModel()
    
    private var navigationTitle: String {
            expenseToEdit == nil ? "Nuevo Gasto" : "Editar Gasto"
        }

    var body: some View {
        NavigationStack {
            Form {
                Section("Detalles del Gasto") {
                    TextField("Descripción", text: $viewModel.description)
                    TextField("Monto", text: $viewModel.amountString)
                        .keyboardType(.decimalPad) // Teclado numérico
                    DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                }

                Section("¿Quién Pagó?") {
                    Picker("Pagador", selection: $viewModel.selectedPayerId) {
                        Text("Seleccionar...").tag(nil as UUID?)
                        ForEach(viewModel.availableMembers()) { member in
                            Text(member.name).tag(member.id as UUID?)
                        }
                    }
                    // Estilo opcional para el Picker dentro de Form
                    // .pickerStyle(.menu)
                }

                Section("¿Para Quiénes?") {
                    // Vista de selección múltiple
                    SelectMembersView(
                        title: "Participantes",
                        members: viewModel.availableMembers(),
                        selectedMemberIds: $viewModel.selectedParticipantIds
                    )
                    .listRowInsets(EdgeInsets())
                    // .frame(minHeight: 150)
                }

                // Mostrar mensaje de error si existe
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .listRowBackground(Color.red.opacity(0.1)) // Resaltar fila
                    }
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        // Intentar guardar a través del ViewModel
                        let success = viewModel.saveExpense(for: group, context: modelContext)
                        if success {
                            
                            dismiss()
                        } else {
                            // Opcional: dar feedback háptico de error
                            // UINotificationFeedbackGenerator().notificationOccurred(.error)
                        }
                    }
                    .disabled(viewModel.description.isEmpty || viewModel.amountString.isEmpty || viewModel.selectedPayerId == nil || viewModel.selectedParticipantIds.isEmpty)
                }
            }
            .task { // Usar .task es preferible a .onAppear para tareas asíncronas o setup
                viewModel.setup(expense: expenseToEdit, members: group.members ?? [])
            }
            // Ocultar teclado al hacer scroll (opcional)
            // .scrollDismissesKeyboard(.interactively)
        }
    }
}

// --- Vista Auxiliar SelectMembersView (sin cambios) ---
struct SelectMembersView: View {
    let title: String
    let members: [Person]
    @Binding var selectedMemberIds: Set<UUID>

    var body: some View {
        List {
             // Opcional: Añadir botones "Seleccionar todos / Ninguno"
             /*
             HStack {
                 Button("Todos") { selectedMemberIds = Set(members.map { $0.id }) }
                 Spacer()
                 Button("Ninguno") { selectedMemberIds = [] }
             }
             .buttonStyle(.borderless)
             .font(.caption)
             .padding(.horizontal)
             */

            ForEach(members) { member in
                HStack {
                    Text(member.name)
                    Spacer()
                    if selectedMemberIds.contains(member.id) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    } else {
                         Image(systemName: "circle")
                             .foregroundStyle(.gray)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if selectedMemberIds.contains(member.id) {
                        selectedMemberIds.remove(member.id)
                    } else {
                        selectedMemberIds.insert(member.id)
                    }
                }
            }
        }
        // Ajustar frame si es necesario o usar dentro de Form
        // .frame(minHeight: 150, maxHeight: 300)
    }
}


// --- Preview (Modificado para probar ambos modos) ---
#Preview("Añadir Gasto") { // Preview para añadir
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
        let p1 = Person(name: "Carlos")
        let p2 = Person(name: "Diana")
        let g = Group(name: "Preview Gasto Grupo")
        g.members = [p1, p2]
        container.mainContext.insert(p1)
        container.mainContext.insert(p2)
        container.mainContext.insert(g)

        // No pasamos expenseToEdit (queda nil)
        return AddExpenseView(group: g)
               .modelContainer(container)
    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}

#Preview("Editar Gasto") { // Preview para editar
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
        let p1 = Person(name: "Carlos")
        let p2 = Person(name: "Diana")
        let g = Group(name: "Preview Gasto Grupo")
        g.members = [p1, p2]
        // Crear un gasto existente para editar
        let existingExpense = Expense(description: "Gasto Viejo", amount: 12.34, date: Date(), payer: p1, participants: [p1, p2], group: g)

        container.mainContext.insert(p1)
        container.mainContext.insert(p2)
        container.mainContext.insert(g)
        container.mainContext.insert(existingExpense) // Insertar el gasto

        // Pasar el expenseToEdit
        return AddExpenseView(group: g, expenseToEdit: existingExpense)
               .modelContainer(container)
    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
