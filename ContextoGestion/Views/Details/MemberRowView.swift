//
//  MemberRowView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 20/05/2025.
//

import SwiftUI

struct MemberRowView: View {
    let member: Person
    
    // Opcional: Podrías pasar el color del grupo para el fondo del avatar
    // let groupColor: Color?

    private func initials(for name: String) -> String {
        name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
            .prefix(2) // Tomar las primeras 2 iniciales
            .map { String($0).uppercased() }
            .joined()
    }

    var body: some View {
        HStack(spacing: 15) { // Un poco más de espacio entre avatar y nombre
            Text(initials(for: member.name))
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white) // Color de las iniciales
                .frame(width: 36, height: 36) // Tamaño del círculo del avatar
                .background(
                    // Usar un color genérico o el color del grupo si se pasa
                    // (groupColor ?? Color.gray).opacity(0.7)
                    Color.gray.opacity(0.5) // Un gris neutro por ahora
                )
                .clipShape(Circle())

            Text(member.name)
                .font(.body) // Fuente estándar para el nombre

            Spacer() // Empuja cualquier contenido adicional (como un chevron) a la derecha

            // Opcional: Añadir un chevron si quieres indicar explícitamente que es tappable
             Image(systemName: "chevron.right")
                 .font(.caption.weight(.bold))
                 .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8) // Padding vertical para dar más aire a la fila
    }
}
