//
//  SettlementCardView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 28/05/2025.
//

import SwiftUI

struct SettlementCardView: View {
    let settlement: FormattedSettlement
    let onConfirmPayment: () -> Void
    @State private var showingConfirmation = false
    @State private var isProcessing = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Contenido principal del pago
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
                    HStack {
                        Image(systemName: "arrowshape.right.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("Paga a")
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundColor(.secondary)
                    }
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
            
            // Botón de confirmar pago
            Button(action: {
                showingConfirmation = true
            }) {
                HStack(spacing: 8) {
                    if isProcessing {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                    }
                    Text(isProcessing ? "Procesando..." : "Confirmar Pago")
                        .font(.system(.subheadline, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    LinearGradient(
                        colors: isProcessing ? [.gray.opacity(0.6), .gray.opacity(0.4)] : [.green, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(isProcessing)
            .confirmationDialog(
                "Confirmar Pago",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Confirmar") {
                    confirmPayment()
                }
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("¿Confirmas que \(settlement.payerName) ya pagó \(settlement.formattedAmount) a \(settlement.payeeName)?")
            }
        }
        .padding(16)
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func confirmPayment() {
        isProcessing = true
        
        // Simular un pequeño delay para mejorar la UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onConfirmPayment()
            isProcessing = false
        }
    }
    
    // MARK: - Helper Methods
    private func initials(for name: String) -> String {
        name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
            .map { String($0).uppercased() }
            .joined()
    }
}

// MARK: - SettlementCardView Previews
#Preview("SettlementCardView Individual") {
    let settlementExample = FormattedSettlement(
        payerName: "Juan Perez",
        payeeName: "Maria Lopez",
        amount: 123.45,
        formattedAmount: "$123,45",
        payerId: UUID(),
        payeeId: UUID()
    )
    
    return SettlementCardView(settlement: settlementExample) {
        print("Pago confirmado!")
    }
    .padding()
    .background(Color(.systemGray5))
}
