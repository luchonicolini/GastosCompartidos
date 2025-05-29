//
//  SettlementCardView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 28/05/2025.
//

import SwiftUI

struct SettlementCardView: View {
    let settlement: FormattedSettlement
    
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
        .padding()
        .background(Material.thin)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
        formattedAmount: "$123,45"
    )
    
    return SettlementCardView(settlement: settlementExample)
        .padding()
        .background(Color(.systemGray5))
}
