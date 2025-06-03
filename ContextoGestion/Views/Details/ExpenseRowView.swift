//
//  ExpenseRowView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 20/05/2025.
//

import SwiftUI

struct ExpenseRowView: View {
    let expense: Expense
    
    // Formateador para la moneda (puedes pasarlo como parámetro si lo tienes centralizado)
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current // Usa la configuración regional del usuario
        formatter.maximumFractionDigits = 2
        return formatter
    }
    
    // Formateador para la fecha (opcional, si quieres mostrarla)
    private static var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short // Ejemplo: "20/5/25"
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Opcional: Icono principal para el gasto
//             Image(systemName: "cart.fill") 
//                 .font(.title2)
//                 .foregroundColor(Color.accentColor) // O el color del grupo: expense.group?.displayColor
//                 .frame(width: 35, height: 35)
//                 .background( (expense.group?.displayColor ?? Color.gray).opacity(0.1) )
//                 .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(expense.expenseDescription)
                    .font(.headline)
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)

                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("Pagó: \(expense.payer?.name ?? "N/A")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                
//                 Text(Self.dateFormatter.string(from: expense.date))
//                     .font(.caption2)
//                     .foregroundColor(.gray)
            }

            Spacer(minLength: 4)

            Text(currencyFormatter.string(from: NSNumber(value: expense.amount)) ?? "")
                .font(.title3.weight(.semibold).monospacedDigit())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 10) 
    }
}
