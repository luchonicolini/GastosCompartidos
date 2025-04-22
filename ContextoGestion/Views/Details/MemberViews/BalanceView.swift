//
//  BalanceView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

// Views/BalanceView.swift
import SwiftUI
import SwiftData // Necesario para Group

struct BalanceView: View {
    // El grupo para el cual mostrar los balances
    let group: Group

    // Usamos @State para el ViewModel ya que esta vista gestionará su ciclo de vida
    // basado en el grupo que recibe.
    @State private var viewModel = GroupDetailViewModel()

    // Estado para mostrar/ocultar las sugerencias de liquidación
    @State private var showingSettlements = false
    @State private var settlements: [String] = []

    // Formateador para mostrar los montos como moneda
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        // Considera establecer el locale si necesitas un símbolo de moneda específico
        // formatter.locale = Locale(identifier: "es_AR") // Ejemplo para Argentina
        formatter.locale = Locale.current // Usar el locale del dispositivo
        return formatter
    }()

    var body: some View {
        VStack {
            if viewModel.memberBalances.isEmpty {
                ContentUnavailableView(
                    "No hay Balances",
                    systemImage: "person.2.slash",
                    description: Text("Añade miembros y gastos al grupo para ver los balances.")
                )
            } else {
                List {
                    Section("Balances Actuales") {
                        ForEach(viewModel.memberBalances) { balanceInfo in
                            HStack {
                                Text(balanceInfo.name)
                                Spacer()
                                Text(currencyFormatter.string(from: NSNumber(value: balanceInfo.balance)) ?? "\(String(format: "%.2f", balanceInfo.balance))")
                                    .foregroundStyle(balanceInfo.balance < -0.01 ? .red : (balanceInfo.balance > 0.01 ? .green : .primary))
                                    .fontWeight(.medium)
                            }
                        }
                    }

                    Section {
                         Button {
                             settlements = viewModel.suggestSettlements() // Calcula las sugerencias
                             showingSettlements = true
                         } label: {
                             Label("Sugerir Liquidaciones", systemImage: "arrow.right.arrow.left.circle")
                         }
                    }
                }
            }
        }
        .navigationTitle("Balances del Grupo")
        // .navigationBarTitleDisplayMode(.inline) // Opcional
        .task {
            // Cuando la vista aparezca (o el grupo cambie si se usa .onChange),
            // configura el viewModel para este grupo.
            // setGroup ya llama a calculateBalances internamente.
            viewModel.setGroup(group)
        }
        // Opcional: Recalcular si las dependencias cambian explícitamente
        // Esto puede ser útil si SwiftData no refresca automáticamente la vista
        // .onChange(of: group.expenses) { _, _ in viewModel.calculateBalances(for: group) }
        // .onChange(of: group.members) { _, _ in viewModel.calculateBalances(for: group) }
        .sheet(isPresented: $showingSettlements) {
             SettlementSuggestionsView(settlements: settlements)
        }
    }
}

// Una vista simple para mostrar las sugerencias en un sheet
struct SettlementSuggestionsView: View {
    let settlements: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView { // Usar NavigationView para tener barra de título y botón Done
            List {
                ForEach(settlements, id: \.self) { suggestion in
                    Text(suggestion)
                }
                // Mostrar mensaje especial si no hay sugerencias (ya saldado)
                if settlements.count == 1 && settlements.first == "¡Todas las cuentas están saldadas!" {
                     Section { // Para que se vea un poco diferente
                         Text(settlements.first!)
                             .foregroundStyle(.secondary)
                     }
                }
            }
            .navigationTitle("Sugerencias de Liquidación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .confirmationAction) { // Botón para cerrar el sheet
                     Button("Hecho") {
                         dismiss()
                     }
                 }
            }
        }
    }
}

// --- Vista Previa (Preview) ---
// Necesitarás configurar un ModelContainer con datos de ejemplo para que funcione.
// Esto es un ejemplo básico, deberías adaptarlo a tu configuración de SwiftData.
#Preview {
    // 1. Crea un contenedor en memoria
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)

    // 2. Crea datos de ejemplo
    let person1 = Person(name: "Ana")
    let person2 = Person(name: "Beto")
    let person3 = Person(name: "Clara")

    let sampleGroup = Group(name: "Viaje a la Costa")
    sampleGroup.members = [person1, person2, person3]

    // Añadir personas y grupo al contexto
    container.mainContext.insert(person1)
    container.mainContext.insert(person2)
    container.mainContext.insert(person3)
    container.mainContext.insert(sampleGroup)

    // Crear algunos gastos de ejemplo (ASUMIENDO que tienes el modelo Expense actualizado)
    let expense1 = Expense(description: "Nafta", amount: 50.0, payer: person1, participants: [person1, person2], group: sampleGroup, splitType: .equally)
    let expense2 = Expense(description: "Cena", amount: 120.0, payer: person2, participants: [person1, person2, person3], group: sampleGroup, splitType: .equally)
    let expense3 = Expense(description: "Peaje", amount: 15.0, payer: person1, participants: [person1, person2], group: sampleGroup, splitType: .equally)
    container.mainContext.insert(expense1)
    container.mainContext.insert(expense2)
    container.mainContext.insert(expense3)


    // Es crucial asignar los gastos al grupo después de insertarlos si la relación inversa
    // no se maneja automáticamente en tu inicializador o modelo.
    // sampleGroup.expenses?.append(expense1) // SwiftData debería manejar esto con la relación inversa

    // 3. Retorna la vista dentro de una NavigationView (opcional)
    return NavigationView {
         BalanceView(group: sampleGroup)
    }
    .modelContainer(container) // Inyecta el contenedor en la vista previa
}
