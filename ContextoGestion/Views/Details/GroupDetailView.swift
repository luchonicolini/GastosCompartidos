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
    // El grupo que se está mostrando. @Bindable permite que si modificamos
    // el nombre del grupo (en una futura EditGroupView), la UI se actualice.
    @Bindable var group: Group

    // El ViewModel para manejar la lógica de esta vista.
    // @StateObject porque esta vista es la "dueña" del estado detallado de ESTE grupo.
    @State private var viewModel = GroupDetailViewModel()

    // Contexto de SwiftData para acciones como eliminar
    @Environment(\.modelContext) private var modelContext

    // Estados para controlar la presentación de las vistas modales (sheets)
    @State private var showingAddExpenseSheet = false
    @State private var showingAddMemberSheet = false
    @State private var expenseToEdit: Expense?
    @State private var memberToEdit: Person?

    // Query para obtener los gastos SÓLO de este grupo, ordenados por fecha
    @Query private var expenses: [Expense]

    // Inicializador para filtrar el @Query por el ID del grupo específico
    init(group: Group) {
        self.group = group
        // Creamos el predicado para filtrar por el ID del grupo
        let groupID = group.id
        let predicate = #Predicate<Expense> { $0.group?.id == groupID }
        
        // Configuramos el Query con el filtro y ordenación
        _expenses = Query(filter: predicate, sort: [SortDescriptor(\Expense.date, order: .reverse)])
    }

    var body: some View {
        List {
            // Sección 1: Balances y Liquidación
            Section("Resumen") {
                // Incluimos la BalanceView directamente aquí
                BalanceView(viewModel: viewModel) // BalanceView usa su propio viewModel interno

                // Enlace para ver las sugerencias de liquidación
                NavigationLink {
                    // Pasamos el viewModel de GroupDetailView a SettlementView
                    SettlementView(viewModel: viewModel)
                } label: {
                    Label("Ver Liquidaciones", systemImage: "arrow.right.arrow.left.circle.fill")
                }
            }

            // Sección 2: Gastos
            Section("Gastos") {
                if expenses.isEmpty {
                    Text("No hay gastos todavía. ¡Añade uno!")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(expenses) { expense in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(expense.expenseDescription)
                                    .fontWeight(.medium)
                                Text("Pagó: \(expense.payer?.name ?? "N/A")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(expense.amount, format: .currency(code: Locale.current.currencyCode ?? "USD"))
                        }
                        .contentShape(Rectangle()) // Para que toda la fila sea tappable
                        .onTapGesture {
                            expenseToEdit = expense // Establece el gasto para editar
                        }
                    }
                    .onDelete(perform: deleteExpense) // Habilitar borrado por swipe
                }
            }

            // Sección 3: Miembros
            Section("Miembros") {
                // Usar group.members directamente, ya que los balances están en BalanceView
                if let members = group.members?.sorted(by: { $0.name < $1.name }), !members.isEmpty {
                    ForEach(members) { member in
                         HStack {
                              Text(member.name)
                              Spacer()
                              // Podríamos mostrar un pequeño icono si quisiéramos
                         }
                         .contentShape(Rectangle())
                         .onTapGesture {
                              memberToEdit = member // Establece el miembro para editar
                         }
                    }
                    .onDelete(perform: deleteMember) // Habilitar borrado por swipe
                } else {
                    Text("No hay miembros en este grupo.")
                        .foregroundStyle(.secondary)
                }
            }
        } // Fin List
        .navigationTitle(group.name)
        // .navigationBarTitleDisplayMode(.inline) // Opcional
        .toolbar {
            // Botón para añadir Gasto
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddExpenseSheet = true
                } label: {
                    Label("Añadir Gasto", systemImage: "plus.circle.fill")
                }
                .disabled(group.members?.isEmpty ?? true)
            }
             // Botón para añadir Miembro
             ToolbarItem(placement: .navigationBarTrailing) {
                  Button {
                       showingAddMemberSheet = true
                  } label: {
                       Label("Añadir Miembro", systemImage: "person.crop.circle.badge.plus")
                  }
             }
            // Podrías añadir un botón de Editar Grupo aquí si implementas EditGroupView
            // ToolbarItem(placement: .navigationBarTrailing) { EditButton() } // O usar EditButton estándar
        }
        .task {
            // Configurar el viewModel cuando la vista aparece por primera vez
            viewModel.setGroup(group)
        }
        // Presentar la hoja para añadir/editar gasto
        .sheet(isPresented: $showingAddExpenseSheet) {
            // Presenta AddExpenseView en modo AÑADIR
            AddExpenseView(group: group)
        }
        .sheet(item: $expenseToEdit) { expense in
             // Presenta AddExpenseView en modo EDITAR
             // Pasamos el grupo y el gasto específico
             AddExpenseView(group: group, expenseToEdit: expense)
        }
        // Presentar la hoja para añadir miembro
        .sheet(isPresented: $showingAddMemberSheet) {
             // Presenta tu AddMemberView
            
           // AddMemberView(group: group, viewModel: viewModel)
            AddMemberView(group: group, viewModel: viewModel)
        }
        // Presentar la hoja para editar miembro
        .sheet(item: $memberToEdit) { member in
             // Presenta EditMemberView
             // Pasamos la persona y ESTE viewModel (GroupDetailViewModel)
             EditMemberView(person: member, viewModel: viewModel)
        }
        // Observar cambios en las relaciones para recalcular balances si es necesario
        // Aunque el viewModel.setGroup en .task lo hace inicialmente, esto podría
        // ayudar si SwiftData no refresca la UI de BalanceView automáticamente.
         .onChange(of: group.expenses?.count) { _, _ in viewModel.calculateBalances(for: group) }
         .onChange(of: group.members?.count) { _, _ in viewModel.calculateBalances(for: group) }

    } // Fin body

    // --- Funciones Auxiliares para Swipe Actions ---

    // Función para borrar gastos
    @MainActor private func deleteExpense(at offsets: IndexSet) {
        offsets.forEach { index in
            // Asegurarse de que el índice es válido para el array filtrado
            if index < expenses.count {
                 let expenseToDelete = expenses[index]
                 viewModel.deleteExpense(expenseToDelete, context: modelContext)
            }
        }
         // No necesitas llamar a calculateBalances aquí si confías en .onChange
    }

    // Función para borrar miembros
    @MainActor private func deleteMember(at offsets: IndexSet) {
         // Obtener miembros ordenados para que el índice coincida
         if let members = group.members?.sorted(by: { $0.name < $1.name }) {
              offsets.forEach { index in
                   if index < members.count {
                        let memberToDelete = members[index]
                        viewModel.removeMember(memberToDelete, from: group, context: modelContext)
                   }
              }
              // No necesitas llamar a calculateBalances aquí si confías en .onChange
         }
    }

}

// --- Vista Previa (Preview) ---
#Preview {
    // 1. Configura contenedor
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)

    // 2. Crea datos de ejemplo
    let p1 = Person(name: "Frodo")
    let p2 = Person(name: "Sam")
    let group = Group(name: "Portadores del Anillo")
    group.members = [p1, p2]
    let expense1 = Expense(description: "Anillo Único", amount: 1000, payer: p1, participants: [p1, p2], group: group)

    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(group)
    container.mainContext.insert(expense1)

    // 3. Retorna la vista dentro de un NavigationStack para que funcionen los links y títulos
    return NavigationStack {
        GroupDetailView(group: group)
    }
    .modelContainer(container)
}
