//
//  GroupRowView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

struct GroupRowView: View {
    // La vista recibe el grupo que debe mostrar
    let group: Group
    
    // Propiedades de estilo (se mantienen)
    private let cardBackgroundColor = Color(.systemGray6)
    private let cornerRadius: CGFloat = 12
    private let shadowRadius: CGFloat = 3
    
    // Formato de fecha para mejor accesibilidad
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                group.displayIcon
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .foregroundStyle(group.displayColor)
                    .frame(width: 40, height: 40)
                    .background(group.displayColor.opacity(0.1))
                    .clipShape(Circle())
                    .accessibilityHidden(true)

                Text(group.name)
                    .font(.system(size: 23, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .accessibilityAddTraits(.isHeader)

                Spacer()
            }

            Divider()

            HStack(alignment: .firstTextBaseline) {
                Label {
                    Text("\(group.members?.count ?? 0) Miembros")
                        .foregroundStyle(.secondary)
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .accessibilityLabel("\(group.members?.count ?? 0) Miembros en el grupo")

                Spacer()

                Label {
                    Text(group.creationDate, style: .date)
                        .foregroundStyle(.secondary)
                } icon: {
                     Image(systemName: "calendar")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
                .foregroundStyle(.tertiary)
                .accessibilityLabel("Creado el \(dateFormatter.string(from: group.creationDate))")
            }
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: .black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Grupo \(group.name) con \(group.members?.count ?? 0) miembros, creado el \(dateFormatter.string(from: group.creationDate))")
    }
}

#Preview {
     do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, configurations: config)

        let p1 = Person(name: "Miembro 1")
        let p2 = Person(name: "Miembro 2")
        let gCustom = Group(
            name: "Grupo Personalizado Simple",
            creationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            iconName: "house.fill",
            colorHex: "#34A853"
        )
        gCustom.members = [p1, p2]

        let gDefault = Group(
            name: "Grupo por Defecto Simple",
             creationDate: Date()
         )

        container.mainContext.insert(p1)
        container.mainContext.insert(p2)
        container.mainContext.insert(gCustom)
        container.mainContext.insert(gDefault)

        return VStack(spacing: 20) {
             GroupRowView(group: gCustom)
             GroupRowView(group: gDefault)
         }
         .padding()
         .modelContainer(container)

    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
