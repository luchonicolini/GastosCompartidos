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
    
    // Propiedades de estilo optimizadas
    private let cardBackgroundColor = Color(.systemGray6)
    private let cornerRadius: CGFloat = 16
    private let shadowColor = Color.black.opacity(0.08)
    private let shadowRadius: CGFloat = 6
    private let titleColor: Color = .primary
    private let subtitleColor: Color = .secondary
    private let verticalPadding: CGFloat = 16
    private let horizontalPadding: CGFloat = 16
    
    // Formato de fecha para mejor accesibilidad
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale.current
        return formatter
    }()
    
    // Computed properties para mejorar la legibilidad
    private var memberCount: Int {
        group.members?.count ?? 0
    }
    
    private var memberText: String {
        memberCount == 1 ? "Miembro" : "Miembros"
    }
    
    private var formattedDate: String {
        dateFormatter.string(from: group.creationDate)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header con ícono y título
            headerSection
            
            // Divider con espaciado optimizado
            Divider()
                .padding(.horizontal, -4) // Extiende ligeramente el divider
            
            // Información del grupo (miembros y fecha)
            groupInfoSection
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Ícono del grupo
            groupIcon
            
            // Nombre del grupo
            Text(group.name)
                .font(.system(size: 20, weight: .medium, design: .rounded))
                .lineLimit(2) // Permite 2 líneas para nombres largos
                .foregroundStyle(titleColor)
                .accessibilityAddTraits(.isHeader)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    @ViewBuilder
    private var groupIcon: some View {
        group.displayIcon
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundStyle(group.displayColor)
            .frame(width: 48, height: 48)
            .background(
                Circle()
                    .fill(group.displayColor.opacity(0.15))
                    .overlay(
                        Circle()
                            .stroke(group.displayColor.opacity(0.25), lineWidth: 1.5)
                    )
            )
            .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var groupInfoSection: some View {
        HStack(alignment: .center, spacing: 12) {
            // Información de miembros
            InfoLabel(
                icon: "person.2.fill",
                text: "\(memberCount) \(memberText)",
                alignment: .leading
            )
            
            Spacer(minLength: 8)
            
            // Información de fecha
            InfoLabel(
                icon: "calendar",
                text: formattedDate,
                alignment: .trailing
            )
        }
        .frame(minHeight: 24) // Altura mínima consistente
    }
    
    // Computed property para accesibilidad
    private var accessibilityDescription: String {
        "Grupo \(group.name) con \(memberCount) \(memberCount == 1 ? "miembro" : "miembros"), creado el \(formattedDate)"
    }
}

// MARK: - InfoLabel Component

struct InfoLabel: View {
    let icon: String
    let text: String
    let alignment: HorizontalAlignment
    
    private let iconColor: Color = .secondary
    private let textColor: Color = .secondary
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 16, height: 16) // Frame fijo para consistencia
            
            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(textColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85) // Escalado ligeramente más permisivo
                .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .leading ? .leading : .trailing)
    }
}

// MARK: - Preview

#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, configurations: config)
        
        // Grupo con varios miembros
        let p1 = Person(name: "Miembro 1")
        let p2 = Person(name: "Miembro 2")
        let p3 = Person(name: "Miembro 3")
        
        let gCustom = Group(
            name: "Grupo con Nombre Muy Largo para Probar",
            creationDate: Calendar.current.date(byAdding: .day, value: -5, to: Date())!,
            iconName: "house.fill",
            colorHex: "#34A853"
        )
        gCustom.members = [p1, p2, p3]
        
        // Grupo con un solo miembro
        let gSingle = Group(
            name: "Solo",
            creationDate: Calendar.current.date(byAdding: .month, value: -2, to: Date())!,
            iconName: "person.fill",
            colorHex: "#FF6B6B"
        )
        gSingle.members = [p1]
        
        // Grupo por defecto sin miembros
        let gDefault = Group(
            name: "Grupo por Defecto",
            creationDate: Date()
        )
        
        container.mainContext.insert(p1)
        container.mainContext.insert(p2)
        container.mainContext.insert(p3)
        container.mainContext.insert(gCustom)
        container.mainContext.insert(gSingle)
        container.mainContext.insert(gDefault)
        
        return ScrollView {
            LazyVStack(spacing: 16) {
                GroupRowView(group: gCustom)
                GroupRowView(group: gSingle)
                GroupRowView(group: gDefault)
            }
            .padding()
        }
        .modelContainer(container)
        
    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
