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
     //let groupColor: Color?

    private func initials(for name: String) -> String {
        name.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .compactMap { $0.first }
            .prefix(2) // Tomar las primeras 2 iniciales
            .map { String($0).uppercased() }
            .joined()
    }

    var body: some View {
        HStack(spacing: 15) {
            Text(initials(for: member.name))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.gray.opacity(0.5))
                .clipShape(Circle())

            Text(member.name)
                .font(.body)
                .lineLimit(2)
                .minimumScaleFactor(0.7)
            
            Spacer()

             Image(systemName: "chevron.right")
                 .font(.caption.weight(.bold))
                 .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}
