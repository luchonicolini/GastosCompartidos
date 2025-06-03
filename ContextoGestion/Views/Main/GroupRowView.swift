//
//  GroupRowView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

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
    
    // Estados para animaciones
    @State private var isPressed = false
    @State private var hoverOffset: CGFloat = 0
    
    // Propiedades de estilo modernizadas
    private let cornerRadius: CGFloat = 20
    private let titleColor: Color = .primary
    private let subtitleColor: Color = .secondary
    private let verticalPadding: CGFloat = 20
    private let horizontalPadding: CGFloat = 20
    
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
        VStack(alignment: .leading, spacing: 18) {
            // Header con ícono y título
            headerSection
            
            // Divider moderno con gradiente
            modernDivider
            
            // Información del grupo (miembros y fecha)
            groupInfoSection
        }
        .padding(.vertical, verticalPadding)
        .padding(.horizontal, horizontalPadding)
        .background(modernCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay(modernBorder)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 8)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .offset(y: hoverOffset)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6).delay(Double.random(in: 0...0.3))) {
                hoverOffset = 0
            }
        }
    }
    
    // MARK: - Modern Background & Effects
    
    @ViewBuilder
    private var modernCardBackground: some View {
        // Glassmorphism effect
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [
                               // Color.primary.opacity(0.1),
                              //Color.primary.opacity(0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
    }
    
    @ViewBuilder
    private var modernBorder: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .strokeBorder(
                LinearGradient(
                    colors: [
                        Color.primary.opacity(0.6),
                        Color.clear,
                        Color.black.opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    @ViewBuilder
    private var modernDivider: some View {
        LinearGradient(
            colors: [
                Color.clear,
                Color.gray.opacity(0.3),
                Color.clear
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(height: 1)
        .padding(.horizontal, -4)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Ícono del grupo modernizado
            modernGroupIcon
            
            // Nombre del grupo
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .foregroundStyle(titleColor)
                    .accessibilityAddTraits(.isHeader)
                
                // Indicador de actividad (opcional)
                HStack(spacing: 4) {
                    Circle()
                        .fill(group.displayColor)
                        .frame(width: 6, height: 6)
                        .opacity(0.8)
                    
                    Text("Activo")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var modernGroupIcon: some View {
        ZStack {
            // Fondo con gradiente
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            group.displayColor.opacity(0.8),
                            group.displayColor.opacity(0.4)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 56, height: 56)
            
            // Borde sutil
            Circle()
                .strokeBorder(group.displayColor.opacity(0.3), lineWidth: 1)
                .frame(width: 56, height: 56)
            
            // Ícono
            group.displayIcon
                .font(.system(size: 24, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
        }
        .accessibilityHidden(true)
    }
    
    @ViewBuilder
    private var groupInfoSection: some View {
        HStack(alignment: .center, spacing: 16) {
            // Información de miembros
            ModernInfoLabel(
                icon: "person.2.fill",
                text: "\(memberCount) \(memberText)",
                color: group.displayColor,
                alignment: .leading
            )
            
            Spacer(minLength: 8)
            
            // Información de fecha
            ModernInfoLabel(
                icon: "calendar",
                text: formattedDate,
                color: .secondary,
                alignment: .trailing
            )
        }
        .frame(minHeight: 28)
    }
    
    // Computed property para accesibilidad
    private var accessibilityDescription: String {
        "Grupo \(group.name) con \(memberCount) \(memberCount == 1 ? "miembro" : "miembros"), creado el \(formattedDate)"
    }
}

// MARK: - Modern InfoLabel Component

struct ModernInfoLabel: View {
    let icon: String
    let text: String
    let color: Color
    let alignment: HorizontalAlignment
    
    var body: some View {
        HStack(spacing: 8) {
            // Ícono con fondo sutil
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 24, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
            
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
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
            LazyVStack(spacing: 20) {
                GroupRowView(group: gCustom)
                GroupRowView(group: gSingle)
                GroupRowView(group: gDefault)
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [Color.gray.opacity(0.1), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .modelContainer(container)
        
    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}
