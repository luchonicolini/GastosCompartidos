//
//  BalanceView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

// Views/BalanceView.swift
// Views/BalanceView.swift
import SwiftUI
import SwiftData 
// --- Vista Principal ---
struct BalanceView: View {
    // Recibe el ViewModel actualizado del padre
    // Asegúrate de que tu GroupDetailViewModel sea @Observable
    let viewModel: GroupDetailViewModel

    // Estado local SÓLO para controlar el sheet de sugerencias
    @State private var showingSettlements = false
    @State private var settlements: [String] = []

    // Formateador de moneda
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        // El contenido de la vista, diseñado para ser incrustado
        // dentro de una Section en la List de GroupDetailView.

        // Verificar si hay balances para mostrar
        if viewModel.memberBalances.isEmpty {
            Text("No hay balances para mostrar. Añade miembros y gastos.")
                .foregroundStyle(.secondary)
                .listRowBackground(Color.clear) // Opcional
        } else {
            // Mostrar la lista de balances
            ForEach(viewModel.memberBalances) { balanceInfo in
                HStack {
                    Text(balanceInfo.name)
                    Spacer()
                    Text(currencyFormatter.string(from: NSNumber(value: balanceInfo.balance)) ?? "\(String(format: "%.2f", balanceInfo.balance))")
                        .foregroundStyle(balanceInfo.balance < -0.01 ? .red : (balanceInfo.balance > 0.01 ? .green : .primary))
                        .fontWeight(.medium)
                }
            }

            // Botón para mostrar las sugerencias (podría estar en GroupDetailView)
            // Lo dejamos aquí como ejemplo si BalanceView tuviera más elementos
            Button {
                settlements = viewModel.suggestSettlements()
                showingSettlements = true
            } label: {
                // Usamos un HStack para que ocupe toda la fila si está en una List
                HStack {
                     Label("Sugerir Liquidaciones", systemImage: "arrow.right.arrow.left.circle")
                     Spacer() // Empuja el texto/icono a la izquierda
                }
                .contentShape(Rectangle()) // Hace toda el área tappable
            }
            // Aplicar el sheet a este botón o a un contenedor superior
            .sheet(isPresented: $showingSettlements) {
                 SettlementSuggestionsView(settlements: settlements)
            }
            // Quitar el estilo de botón por defecto si está dentro de una lista
            // para que no se vea el fondo azul típico
            .buttonStyle(.plain)


        }
        // Ya no hay .task ni .navigationTitle aquí
    }
}

// --- Vista para mostrar Sugerencias en un Sheet ---
// (Puedes mantenerla aquí o moverla a su propio archivo)
struct SettlementSuggestionsView: View {
    let settlements: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                // Mensaje especial si todo está saldado
                if settlements.count == 1 && settlements.first == "¡Todas las cuentas están saldadas!" {
                    Text(settlements.first!)
                        .foregroundStyle(.secondary)
                } else {
                    // Lista de sugerencias normales
                    ForEach(settlements, id: \.self) { suggestion in
                        Text(suggestion)
                    }
                }
            }
            .navigationTitle("Sugerencias de Liquidación")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                 ToolbarItem(placement: .confirmationAction) {
                     Button("Hecho") {
                         dismiss()
                     }
                 }
            }
        }
    }
}


// --- Vista Previa (Preview) ---
#Preview {
    // 1. Configura contenedor
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)

    // 2. Crea datos de ejemplo
    let p1 = Person(name: "Ana")
    let p2 = Person(name: "Beto")
    let group = Group(name: "Preview Group")
    group.members = [p1, p2]
    let expense1 = Expense(description: "Comida", amount: 50.0, payer: p1, participants: [p1, p2], group: group)

    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(group)
    container.mainContext.insert(expense1)

    // 3. Crea instancia de ViewModel para el Preview
    let previewViewModel = GroupDetailViewModel()
    // Forzar cálculo de balances para la preview
    // Usamos MainActor.assumeIsolated porque setGroup es @MainActor
    // y el contexto del Preview puede no serlo.
    MainActor.assumeIsolated {
        previewViewModel.setGroup(group)
    }

    // 4. Retorna la vista dentro de una List para simular GroupDetailView
    return List {
        Section("Balances (Preview)") {
             // Pasar el viewModel creado para la preview
             BalanceView(viewModel: previewViewModel)
        }
    }
    .modelContainer(container) // Inyecta el contenedor
}
