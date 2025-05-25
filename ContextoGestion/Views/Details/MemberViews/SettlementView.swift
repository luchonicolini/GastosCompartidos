//
//  SettlementView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

// Views/SettlementView.swift
import SwiftUI
import SwiftData

struct SettlementView: View {
    @State var viewModel: GroupDetailViewModel
    @State private var Fsettlements: [FormattedSettlement] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Calculando liquidaciones...")
                    .frame(maxHeight: .infinity)
            } else if Fsettlements.isEmpty {
                ContentUnavailableView(
                    "Todo Saldado",
                    systemImage: "checkmark.circle.fill",
                    description: Text("¡Excelente! No hay deudas pendientes en este grupo.")
                )
                .foregroundStyle(.green)
                .frame(maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Pagos Sugeridos")
                            .font(.title2.bold())
                            .padding(.bottom, 5)
                            .padding(.horizontal)
                        
                        ForEach(Fsettlements) { settlement in
                            SettlementCardView(settlement: settlement)
                        }
                        .padding(.horizontal)
                        
                        Button {
                            Task { await calculateSettlements() }
                        } label: {
                            Label("Refrescar Sugerencias", systemImage: "arrow.clockwise.circle.fill")
                                .font(.headline)
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .foregroundColor(.blue)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        .padding(.bottom)
                        
                    }
                    .padding(.vertical)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color("AppBackground"))
        .navigationTitle("Liquidar Cuentas")
        .task {
            await calculateSettlements()
        }
        .onChange(of: viewModel.memberBalances) {
            Task { await calculateSettlements() }
        }
    }
    
    @MainActor
    private func calculateSettlements() async {
        isLoading = true
        self.Fsettlements = viewModel.suggestFormattedSettlements()
        isLoading = false
    }
}

#Preview("SettlementView Rediseñada") {
    let previewViewModel = GroupDetailViewModel()
    previewViewModel.memberBalances = [
        MemberBalance(id: UUID(), name: "Luciano Nicolini", balance: -130.00),
        MemberBalance(id: UUID(), name: "Gema Bot", balance: 150.00),
        MemberBalance(id: UUID(), name: "Ana Pérez", balance: -75.50),
        MemberBalance(id: UUID(), name: "Carlos Sol", balance: 75.50),
        MemberBalance(id: UUID(), name: "Laura Mar", balance: -20.00)
    ]
    
    return NavigationView {
        SettlementView(viewModel: previewViewModel)
    }
}

#Preview("SettlementView Vacía") {
    let previewViewModel = GroupDetailViewModel()
    previewViewModel.memberBalances = [
        MemberBalance(id: UUID(), name: "Persona A", balance: 0),
        MemberBalance(id: UUID(), name: "Persona B", balance: 0)
    ]
    
    return NavigationView {
        SettlementView(viewModel: previewViewModel)
    }
}

#Preview("SettlementCardView Individual") {
    let settlementExample = FormattedSettlement(
        payerName: "Juan Perez",
        payeeName: "Maria Lopez",
        amount: 123.45,
        formattedAmount: "$123,45"
    )
    return SettlementCardView(settlement: settlementExample)
        .padding()
        .background(Color(.systemGray5))
}


// En SettlementView.swift (o SettlementCardView.swift)

struct SettlementCardView: View {
    let settlement: FormattedSettlement // Asume que FormattedSettlement tiene payerName, payeeName, formattedAmount
    
    private func initials(for name: String) -> String {
        name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Sección Pagador
            VStack(spacing: 4) {
                Text(initials(for: settlement.payerName))
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.red.opacity(0.8))
                    .clipShape(Circle())
                Text(settlement.payerName.split(separator: " ").first ?? "")
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 70)
            
            // Flecha y Monto
            VStack(spacing: 2) {
                Text(settlement.formattedAmount)
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Image(systemName: "arrow.right.long")
                    .font(.title3)
                    .foregroundColor(.secondary)
                Text("paga a") 
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            
            // Sección Receptor
            VStack(spacing: 4) {
                Text(initials(for: settlement.payeeName))
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.green.opacity(0.8))
                    .clipShape(Circle())
                Text(settlement.payeeName.split(separator: " ").first ?? "")
                    .font(.caption)
                    .lineLimit(1)
            }
            .frame(width: 70)
        }
        .padding()
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
