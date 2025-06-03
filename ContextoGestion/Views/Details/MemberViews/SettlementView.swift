//
//  SettlementView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

struct SettlementView: View {
    @State var viewModel: GroupDetailViewModel
    @State private var Fsettlements: [FormattedSettlement] = []
    @State private var isLoading: Bool = true
    @State private var showingSuccessMessage = false
    @State private var successMessage = ""
    @Environment(\.modelContext) private var modelContext
    
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
                        // Header con información útil
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pagos Sugeridos")
                                .font(.title2.bold())
                            
                            Text("Toca 'Confirmar Pago' cuando el dinero se haya transferido en la vida real")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.bottom, 5)
                        }
                        .padding(.horizontal)
                        
                        // Lista de pagos sugeridos
                        ForEach(Fsettlements) { settlement in
                            SettlementCardView(settlement: settlement) {
                                // Esta es la acción que se ejecuta cuando se confirma un pago
                                confirmPayment(settlement)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Botón de refrescar
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
            
            // Mensaje de éxito
            if showingSuccessMessage {
                VStack {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(successMessage)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .padding(.horizontal)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
    
    // MARK: - Private Methods
    
    @MainActor
    private func calculateSettlements() async {
        isLoading = true
        self.Fsettlements = viewModel.suggestFormattedSettlements()
        isLoading = false
    }
    
    @MainActor private func confirmPayment(_ settlement: FormattedSettlement) {
        do {
            try viewModel.confirmSettlementPayment(settlement, context: modelContext)
            
            // Mostrar mensaje de éxito
            successMessage = "✅ Pago confirmado: \(settlement.payerName) → \(settlement.payeeName)"
            showingSuccessMessage = true
            
            // Ocultar mensaje después de 3 segundos
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showingSuccessMessage = false
                }
            }
            
            // Recalcular inmediatamente
            Task { await calculateSettlements() }
            
        } catch {
            // Manejar errores si es necesario
            print("Error al confirmar pago: \(error)")
            // Aquí podrías mostrar un alert de error si quieres
        }
    }
}

// MARK: - SettlementView Previews
#Preview("SettlementView con Pagos Pendientes") {
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
            .modelContainer(for: [Expense.self, Person.self, Group.self, SettlementPayment.self])
    }
}

#Preview("SettlementView Todas las Cuentas Saldadas") {
    let previewViewModel = GroupDetailViewModel()
    previewViewModel.memberBalances = [
        MemberBalance(id: UUID(), name: "Persona A", balance: 0),
        MemberBalance(id: UUID(), name: "Persona B", balance: 0)
    ]
    
    return NavigationView {
        SettlementView(viewModel: previewViewModel)
            .modelContainer(for: [Expense.self, Person.self, Group.self, SettlementPayment.self])
    }
}



