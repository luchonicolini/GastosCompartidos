//
//  BalanceCardView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 20/05/2025.
//

// Archivo: BalanceCardView.swift (o puedes poner esta struct dentro de BalanceView.swift si lo prefieres)
import SwiftUI

struct BalanceCardView: View {
    let balanceInfo: MemberBalance // Asumo que MemberBalance es la struct que usas
    let currencyFormatter: NumberFormatter

    var body: some View {
        HStack(spacing: 12) {
            // Icono indicativo (opcional, pero puede añadir claridad)
            Image(systemName: balanceIconName)
                .font(.title2)
                .fontWeight(.light)
                .frame(width: 30, alignment: .center) // Ancho fijo para el icono
                .foregroundColor(balanceColor)

            VStack(alignment: .leading, spacing: 2) {
                Text(balanceInfo.name)
                    .font(.system(.headline, design: .rounded)) // Un poco más de estilo en la fuente
                    .fontWeight(.medium)
                    .foregroundColor(.primary) // Color primario para el nombre

                Text(balanceStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary) // Color secundario para el estado
            }

            Spacer() // Empuja el monto hacia la derecha

            Text(currencyFormatter.string(from: NSNumber(value: balanceInfo.balance)) ?? "\(String(format: "%.2f", balanceInfo.balance))")
                .font(.system(.title3, design: .rounded).weight(.semibold)) // Monto más prominente
                .foregroundColor(balanceColor) // Color según el saldo
        }
        .padding() // Padding interno de la tarjeta
        .background(Material.thin) // Efecto translúcido moderno (como las notificaciones de iOS)
                                    // Alternativa: Color(.systemGray6) para un fondo sólido claro
        .clipShape(RoundedRectangle(cornerRadius: 12)) // Esquinas redondeadas
        // .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2) // Sombra sutil opcional
    }

    // Lógica para determinar el color y el icono basado en el saldo
    private var balanceColor: Color {
        if balanceInfo.balance < -0.01 {
            return .red
        } else if balanceInfo.balance > 0.01 {
            return .green
        } else {
            return .primary // O .secondary si prefieres que el cero sea menos prominente
        }
    }

    private var balanceIconName: String {
        if balanceInfo.balance < -0.01 {
            return "arrow.down.right.circle.fill" // O "minus.circle.fill"
        } else if balanceInfo.balance > 0.01 {
            return "arrow.up.right.circle.fill" // O "plus.circle.fill"
        } else {
            return "equal.circle.fill" // Icono para saldo cero
        }
    }
    
    private var balanceStatusText: String {
        if balanceInfo.balance < -0.01 {
            return "Debe"
        } else if balanceInfo.balance > 0.01 {
            return "Le deben"
        } else {
            return "Saldo neutro"
        }
    }
}
