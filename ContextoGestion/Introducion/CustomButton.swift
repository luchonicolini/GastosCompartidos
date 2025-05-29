//
//  CustomButton.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 19/05/2025.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    var iconSystemName: String? = nil // Icono opcional
    let enabledColor: Color // Color cuando está habilitado
    let action: () -> Void

    // Ajusta estos valores según tus preferencias para el contexto de la lista
    let height: CGFloat = 50
    let fontStyle: Font = .headline.weight(.semibold)
    let cornerRadius: CGFloat = 12

    // Colores y offset basados en el estado de habilitación y presión
    private var activeColor: Color { isEnabled ? enabledColor : Color.gray }
    private var baseColor: Color { isEnabled ? enabledColor.opacity(0.7) : Color.gray.opacity(0.4) }
    private var currentOffsetY: CGFloat { (isEnabled && !isPressed) ? -5 : 0 } // Menor offset para un look más sutil en lista

    @State private var isPressed = false // Solo para el efecto visual cuando está habilitado
    @Environment(\.isEnabled) private var isEnabled // Para reaccionar al estado .disabled()

    var body: some View {
        ZStack {
            // Capa base para el efecto 3D
            RoundedRectangle(cornerRadius: cornerRadius)
                .foregroundStyle(baseColor)
            
            // Capa superior que se mueve
            RoundedRectangle(cornerRadius: cornerRadius)
                .foregroundStyle(activeColor)
                .offset(y: currentOffsetY)
                .overlay {
                    HStack(spacing: 8) {
                        if let iconName = iconSystemName, !iconName.isEmpty {
                            Image(systemName: iconName)
                                .imageScale(.medium) // Escala el icono con la fuente
                        }
                        Text(title)
                    }
                    .font(fontStyle)
                    .foregroundStyle(.white)
                    .offset(y: currentOffsetY) // Mover el contenido con la capa superior
                }
        }
        .frame(maxWidth: .infinity, idealHeight: height) // Ocupar el ancho, altura ideal
        .frame(height: height) // Forzar la altura
        .contentShape(Rectangle()) // Asegura que toda el área del ZStack sea tappable
        .onTapGesture {
            if isEnabled { // Solo ejecutar la acción si está habilitado
                action()
                // Puedes añadir un feedback háptico aquí si lo deseas
                // UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if isEnabled { // El efecto de presión solo si está habilitado
                        withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    // isPressed solo se establece en true si estaba habilitado
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isPressed = false
                    }
                }
        )
        .opacity(isEnabled ? 1.0 : 0.65) // Opacidad reducida cuando está deshabilitado
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed) // Animar el estado de presión
        .animation(.default, value: isEnabled) // Animar cambios en el estado habilitado/deshabilitado
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    CustomButton(title: "zxzx", enabledColor: .blue, action: {})
    .padding()
}
