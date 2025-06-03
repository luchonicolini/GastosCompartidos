//
//  CustomAlertView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 30/04/2025.
//

//
//  CustomAlertView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 30/04/2025.
//

import SwiftUI

// Estructura para definir un botón en la alerta personalizada
struct AlertButton: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    var role: ButtonRole? = .none
    let action: () -> Void
}

// Enum para diferentes tipos de alerta
enum AlertType {
    case info
    case warning
    case error
    case success
    
    var iconName: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        case .success: return "checkmark.circle.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        case .success: return .green
        }
    }
}

// La vista de la alerta personalizada mejorada
struct CustomAlertView: View {
    @Binding var isPresented: Bool
    
    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let buttons: [AlertButton]
    let type: AlertType?
    
    // Para animaciones y apariencia
    @State private var scale: CGFloat = 0.7
    @State private var opacity: Double = 0.0
    @State private var backgroundOpacity: Double = 0.0
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    init(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttons: [AlertButton],
        type: AlertType? = nil
    ) {
        self._isPresented = isPresented
        self.title = title
        self.message = message
        self.buttons = buttons
        self.type = type
    }
    
    var body: some View {
        ZStack {
            // Fondo oscuro/difuminado original
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                    if !buttons.contains(where: { $0.role == .cancel }) {
                        dismissAlert()
                    }
                }
            
            // Contenido de la alerta
            alertContent
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .ignoresSafeArea(.container, edges: .all)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.5, dampingFraction: 0.8)) {
                scale = 1.0
                opacity = 1.0
                backgroundOpacity = 1.0
            }
        }
    }
    
    private var alertContent: some View {
        VStack(spacing: 0) {
            // Header con icono opcional
            headerSection
            
            // Contenido principal
            contentSection
            
            // Divisor horizontal
            Divider()
            
            // Botones
            buttonsSection
        }
        .background(Material.regular) // Manteniendo el fondo original
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .shadow(
            color: .black.opacity(0.2),
            radius: 10,
            x: 0,
            y: 5
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(
                    colorScheme == .dark ? .white.opacity(0.1) : .gray.opacity(0.2),
                    lineWidth: 0.5
                )
        )
        .padding(.horizontal, 30)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: type != nil ? 12 : 0) {
            if let type = type {
                Image(systemName: type.iconName)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(type.iconColor)
                    .symbolEffect(.bounce, value: isPresented)
            }
            
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(Color.primaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
        .padding(.horizontal)
        .padding(.bottom, message == nil ? 20 : 5)
    }
    
    @ViewBuilder
    private var contentSection: some View {
        if let message = message {
            Text(message)
                .font(.body)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
        }
    }
    
    private var buttonsSection: some View {
        HStack(spacing: 0) {
            ForEach(buttons.indices, id: \.self) { index in
                Button {
                    buttons[index].action()
                    dismissAlert()
                } label: {
                    Text(buttons[index].title)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .fontWeight(buttonFontWeight(for: buttons[index]))
                .foregroundStyle(buttonColor(for: buttons[index]))
                
                if index < buttons.count - 1 {
                    Divider()
                }
            }
        }
        .frame(height: 50)
        .background(Color.secondary.opacity(0.1))
    }
    
    // Funciones auxiliares para estilos de botones
    private func buttonColor(for button: AlertButton) -> Color {
        switch button.role {
        case .destructive:
            return .red
        case .cancel:
            return Color.primaryText
        default:
            return Color.primaryText
        }
    }
    
    private func buttonFontWeight(for button: AlertButton) -> Font.Weight {
        switch button.role {
        case .cancel:
            return .regular
        default:
            return .semibold
        }
    }
    
    // Función para cerrar la alerta con animación mejorada
    private func dismissAlert() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            scale = 0.8
            isPresented = false
        }
    }
}

// Extensiones mejoradas
extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        buttons: [AlertButton],
        type: AlertType? = nil
    ) -> some View {
        self.overlay {
            if isPresented.wrappedValue {
                CustomAlertView(
                    isPresented: isPresented,
                    title: title,
                    message: message,
                    buttons: buttons,
                    type: type
                )
            }
        }
    }
    
    // Sobrecarga para alerta simple
    func customAlert(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil,
        type: AlertType? = nil
    ) -> some View {
        customAlert(
            isPresented: isPresented,
            title: title,
            message: message,
            buttons: [AlertButton(title: "OK", action: {})],
            type: type
        )
    }
}

// --- Vistas Previa Mejoradas ---
#Preview("Alerta de Éxito") {
    @State var showAlert = true
    return ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        
        if showAlert {
            CustomAlertView(
                isPresented: $showAlert,
                title: "¡Operación Exitosa!",
                message: "Los cambios se han guardado correctamente.",
                buttons: [
                    AlertButton(title: "Continuar", action: { print("Continue") })
                ],
                type: .success
            )
        }
    }
}

#Preview("Alerta de Error") {
    @State var showAlert = true
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        if showAlert {
            CustomAlertView(
                isPresented: $showAlert,
                title: "Error de Conexión",
                message: "No se pudo conectar al servidor. Por favor, verifica tu conexión a internet.",
                buttons: [
                    AlertButton(title: "Cancelar", role: .cancel, action: {}),
                    AlertButton(title: "Reintentar", action: {})
                ],
                type: .error
            )
        }
    }
}

#Preview("Alerta de Confirmación") {
    @State var showAlert = true
    return ZStack {
        Color.gray.opacity(0.1).ignoresSafeArea()
        
        if showAlert {
            CustomAlertView(
                isPresented: $showAlert,
                title: "¿Eliminar elemento?",
                message: "Esta acción no se puede deshacer.",
                buttons: [
                    AlertButton(title: "Cancelar", role: .cancel, action: {}),
                    AlertButton(title: "Eliminar", role: .destructive, action: {})
                ],
                type: .warning
            )
        }
    }
}

