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
                AllSettledView()
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


// MARK: - SettlementView Previews
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



