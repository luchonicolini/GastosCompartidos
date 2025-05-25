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
    private let cornerRadius: CGFloat = 16 // Aumentado el radio de las esquinas
    private let shadowColor = Color.black.opacity(0.08) // Sombra más suave
    private let shadowRadius: CGFloat = 6 // Aumentado el radio de la sombra
    private let titleColor: Color = .primary // Color del título
    private let subtitleColor: Color = .secondary // Color del subtítulo
    private let verticalPadding: CGFloat = 12 // Aumentado el padding vertical
    private let horizontalPadding: CGFloat = 16
    
    // Formato de fecha para mejor accesibilidad
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current // Usa el locale del usuario
        return formatter
    }()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                group.displayIcon
                    .font(.system(size: 24, weight: .semibold, design: .rounded)) // Icono más grande y con más peso
                    .foregroundStyle(group.displayColor)
                    .frame(width: 48, height: 48) // Tamaño fijo para el icono
                    .background(group.displayColor.opacity(0.15))
                    .clipShape(Circle())
                    .accessibilityHidden(true)
                    .overlay( // Añadido un borde circular opcional
                        Circle()
                            .stroke(group.displayColor.opacity(0.2), lineWidth: 1)
                    )
                
                Text(group.name)
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .foregroundStyle(titleColor) // Usa el color definido
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
            }
            
            Divider()
            
            HStack(alignment: .top) { // <-- CAMBIO 1: Alineación a .top
                Label {
                    Text("\(group.members?.count ?? 0) \(group.members?.count == 1 ? "Miembro" : "Miembros")")
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(subtitleColor)
                .accessibilityLabel("\(group.members?.count ?? 0) \(group.members?.count == 1 ? "Miembro" : "Miembros") en el grupo")
                
                Spacer()
                
                Label {
                      Text(dateFormatter.string(from: group.creationDate))
                    
                          .lineLimit(2)
                          .minimumScaleFactor(0.70)
                          .multilineTextAlignment(.trailing)
                  } icon: {
                      Image(systemName: "calendar")
                  }
                  .font(.system(size: 15, weight: .medium, design: .rounded))
                  .foregroundStyle(subtitleColor)
                .accessibilityLabel("Creado el \(dateFormatter.string(from: group.creationDate))")
            }
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Grupo \(group.name) con \(group.members?.count ?? 0) \(group.members?.count == 1 ? "miembro" : "miembros"), creado el \(dateFormatter.string(from: group.creationDate))")
    }
}

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, configurations: config)
        
        let p1 = Person(name: "Miembro 1")
        let p2 = Person(name: "Miembro 2")
        let gCustom = Group(
            name: "Grupo Personalizado",
            creationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            iconName: "house.fill",
            colorHex: "#34A853"
        )
        gCustom.members = [p1, p2]
        
        let gDefault = Group(
            name: "Grupo por Defecto",
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
