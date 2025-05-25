//
//  BalanceView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//


import SwiftUI
import SwiftData 

struct BalanceView: View {
    let viewModel: GroupDetailViewModel

    // Formateador de moneda (se mantiene)
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 2
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if viewModel.memberBalances.isEmpty {
                Text("No hay balances para mostrar. Añade miembros y gastos.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical)
            } else {
                ForEach(viewModel.memberBalances) { balanceInfo in
                    BalanceCardView(balanceInfo: balanceInfo, currencyFormatter: currencyFormatter)
                }
            }
        }
    }
}



// --- Vista Previa (Preview) ---
#Preview("BalanceView con Tarjetas") {

    // 2. Crea datos de ejemplo USANDO MemberBalance
    let mb1 = MemberBalance(id: UUID(), name: "Ana García", balance: -25.50)
    let mb2 = MemberBalance(id: UUID(), name: "Carlos Vera", balance: 150.75)
    let mb3 = MemberBalance(id: UUID(), name: "Laura Pausini", balance: 0.00)
    let mb4 = MemberBalance(id: UUID(), name: "Pedro Suárez", balance: -10.00)

    // 3. Crea instancia de ViewModel para el Preview
    let previewViewModel = GroupDetailViewModel()
    // Asignar los MemberBalance directamente al ViewModel para el preview
    previewViewModel.memberBalances = [mb1, mb2, mb3, mb4]

    return ScrollView {
        BalanceView(viewModel: previewViewModel)
            .padding()
    }
    // .modelContainer(container) // Solo si fuera necesario para el preview
    .background(Color(.systemGroupedBackground))
}

#Preview("BalanceCard Individual") {
     let formatter = NumberFormatter()
     formatter.numberStyle = .currency
     formatter.maximumFractionDigits = 2
     formatter.locale = Locale.current

    return VStack(spacing: 10) {
        BalanceCardView(
            balanceInfo: MemberBalance(id: UUID(), name: "Luciano Deudor", balance: -123.45),
            currencyFormatter: formatter
        )
        BalanceCardView(
            balanceInfo: MemberBalance(id: UUID(), name: "Gema Acreedora", balance: 567.89),
            currencyFormatter: formatter
        )
        BalanceCardView(
            balanceInfo: MemberBalance(id: UUID(), name: "Neutral Nico", balance: 0.00),
            currencyFormatter: formatter
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
