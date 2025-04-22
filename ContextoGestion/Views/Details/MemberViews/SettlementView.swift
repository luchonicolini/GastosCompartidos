//
//  SettlementView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

// Views/SettlementView.swift
import SwiftUI
import SwiftData // Necesario si pasas el Group, aunque aquí usamos el ViewModel

struct SettlementView: View {
    // Usamos el ViewModel que ya tiene la lógica y los datos necesarios.
    // Asumimos que se pasa desde la vista padre (ej. GroupDetailView).
    @State var viewModel: GroupDetailViewModel

    // Estado para almacenar las sugerencias calculadas
    @State private var settlements: [String] = []

    var body: some View {
        VStack {
            if settlements.isEmpty {
                 // Muestra un indicador mientras calcula o si hay error (aunque suggestSettlements devuelve array)
                 ProgressView("Calculando liquidaciones...")
                     .onAppear(perform: calculateSettlements) // Calcular al aparecer
            } else if settlements.count == 1 && settlements.first == "¡Todas las cuentas están saldadas!" {
                // Mensaje especial si todo está saldado
                ContentUnavailableView(
                    "Todo Saldado",
                    systemImage: "checkmark.circle.fill",
                    description: Text("¡Excelente! No hay deudas pendientes en este grupo.")
                )
                .foregroundStyle(.green)
            } else {
                // Muestra la lista de sugerencias
                List {
                    Section("Pagos Sugeridos para Saldar Deudas") {
                        ForEach(settlements, id: \.self) { suggestion in
                            // Podrías parsear el string para un formato más rico si quisieras
                            // Por ejemplo: extraer nombres y monto para usar iconos o formato distinto
                            Text(suggestion)
                        }
                    }
                     Section { // Sección para el botón de refrescar
                         Button {
                              calculateSettlements() // Volver a calcular
                         } label: {
                              Label("Refrescar Sugerencias", systemImage: "arrow.clockwise")
                         }
                     }
                }
            }
        }
        .navigationTitle("Liquidar Cuentas")
        //.navigationBarTitleDisplayMode(.inline) // Opcional
        // Calcular la primera vez que aparece la vista
        // .onAppear(perform: calculateSettlements) // Movido al ProgressView/List para mejor manejo
         // Opcional: Recalcular si las dependencias cambian, aunque un botón de refrescar es más explícito
         // .onChange(of: viewModel.memberBalances) { _, _ in calculateSettlements() }

    }

    // Función para llamar al cálculo en el ViewModel
    @MainActor private func calculateSettlements() {
         // Llama a la función del ViewModel que ya tienes implementada
         settlements = viewModel.suggestSettlements()
    }
}

// --- Vista Previa (Preview) ---
#Preview {
    // 1. Configura el contenedor en memoria
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)

    // 2. Crea datos de ejemplo (más elaborados para generar deudas)
    let p1 = Person(name: "Ana")
    let p2 = Person(name: "Beto")
    let p3 = Person(name: "Carlos")

    let group = Group(name: "Grupo con Deudas")
    group.members = [p1, p2, p3]

    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)
    container.mainContext.insert(group)

    // Gastos que generen deudas cruzadas
    let ex1 = Expense(description: "Comida Ana", amount: 90.0, payer: p1, participants: [p1, p2, p3], group: group, splitType: .equally) // Ana paga 90, debe recibir 60. A:-30, B:-30, C:-30 -> A:+60, B:-30, C:-30
    let ex2 = Expense(description: "Bebidas Beto", amount: 30.0, payer: p2, participants: [p1, p2, p3], group: group, splitType: .equally) // Beto paga 30, debe recibir 20. A:-10, B:-10, C:-10 -> A:+60-10=50, B:-30+20=-10, C:-30-10=-40
    let ex3 = Expense(description: "Taxi Carlos", amount: 15.0, payer: p3, participants: [p1, p3], group: group, splitType: .equally) // Carlos paga 15 (participan A y C), debe recibir 7.5. A:-7.5, C:-7.5 -> A:50-7.5=42.5, B:-10, C:-40+7.5=-32.5

    container.mainContext.insert(ex1)
    container.mainContext.insert(ex2)
    container.mainContext.insert(ex3)


    // 3. Crea una instancia del ViewModel y configúrala
    let previewViewModel = GroupDetailViewModel()
    MainActor.assumeIsolated {
         previewViewModel.setGroup(group) // Esto calcula los balances iniciales
    }

    // 4. Retorna la vista dentro de una NavigationView
    return NavigationView {
        SettlementView(viewModel: previewViewModel)
    }
    .modelContainer(container)
}
