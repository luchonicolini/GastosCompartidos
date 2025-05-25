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

// La vista de la alerta personalizada
struct CustomAlertView: View {
    @Binding var isPresented: Bool // Binding para controlar la visibilidad

    let title: LocalizedStringKey
    let message: LocalizedStringKey?
    let buttons: [AlertButton]

    // Para animaciones y apariencia
    @State private var scale: CGFloat = 0.8
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    var body: some View {
        ZStack {
            // Fondo oscuro/difuminado
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .transition(.opacity)
                .onTapGesture {
                     if buttons.contains(where: { $0.role == .cancel }) == false {
                         dismissAlert()
                     }
                }

            // Contenido de la Alerta
            VStack(spacing: 0) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.primaryText)
                    .padding(.top, 20)
                    .padding(.bottom, message == nil ? 20 : 5)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)


                // Mensaje (opcional)
                if let message = message {
                    Text(message)
                        .font(.body)
                        .foregroundStyle(Color.secondary)
                        .padding(.horizontal)
                        .padding(.bottom)
                        .multilineTextAlignment(.center)

                }

                // Divisor horizontal
                Divider()

                // Botones
                HStack(spacing: 0) {
                    ForEach(buttons.indices, id: \.self) { index in
                        Button {
                            buttons[index].action() // Ejecuta la acción del botón
                            dismissAlert()        // Cierra la alerta
                        } label: {
                            Text(buttons[index].title)
                                .frame(maxWidth: .infinity, maxHeight: .infinity) // Ocupa todo el espacio disponible
                                .contentShape(Rectangle()) // Hace todo el botón tappable
                        }
                        .buttonStyle(.plain) // Quita estilo por defecto
                        .fontWeight(buttons[index].role == .cancel ? .regular : .semibold)
                        .foregroundStyle(buttons[index].role == .destructive ? Color.red : Color.primaryText)

                        // Añadir divisor vertical si no es el último botón
                        if index < buttons.count - 1 {
                            Divider()
                        }
                    }
                }
                .frame(height: 50)
                .background(Color.secondary.opacity(0.1))


            } // Fin VStack contenido
            .background(Material.regular) // Fondo con efecto blur/material
            // Usa tu color de fondo secundario si prefieres un color sólido:
           // .background(Color.primaryText)
            .clipShape(RoundedRectangle(cornerRadius: 15))
            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            .padding(.horizontal, 30)
            .scaleEffect(scale)
            .transition(.opacity.combined(with: .scale(scale: 0.85)))


        }
        .ignoresSafeArea(.container, edges: .all)
        .onAppear {
            withAnimation(reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.7)) {
                scale = 1.0
            }
        }
    }

    // Función para cerrar la alerta con animación
    private func dismissAlert() {
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
            scale = 0.8
            isPresented = false
        }
    }
}

// --- Vista Previa ---
#Preview("Alerta Simple") {
    @State var showAlert = true
    return ZStack {
        // Fondo de ejemplo
        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        Text("Contenido detrás")

        // La alerta personalizada
        if showAlert {
            CustomAlertView(
                isPresented: $showAlert,
                title: "Título de Prueba",
                message: "Este es un mensaje de ejemplo un poco más largo para ver cómo se ajusta.",
                buttons: [
                    AlertButton(title: "OK", action: { print("OK Tapped") })
                ]
            )
        }
    }
}

#Preview("Alerta con 2 Botones") {
    @State var showAlert = true
    return ZStack {
        // Fondo de ejemplo
         Color.gray.opacity(0.2).ignoresSafeArea()
        Text("Contenido detrás")

        // La alerta personalizada
        if showAlert {
            CustomAlertView(
                isPresented: $showAlert,
                title: "¿Confirmar Acción?",
                message: "Esta acción no se puede deshacer.",
                buttons: [
                    AlertButton(title: "Cancelar", role: .cancel, action: { print("Cancel Tapped") }),
                    AlertButton(title: "Confirmar", role: .destructive, action: { print("Confirm Tapped") })
                ]
            )
        }
    }
}



// Extensión para presentar la alerta personalizada fácilmente
extension View {
    func customAlert(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil, // Mensaje opcional
        buttons: [AlertButton]
    ) -> some View {
        self.overlay { // O usar ZStack si el overlay da problemas con otros elementos
            if isPresented.wrappedValue {
                CustomAlertView(
                    isPresented: isPresented,
                    title: title,
                    message: message,
                    buttons: buttons
                )
            }
        }
    }

    // Sobrecarga útil para alertas simples con un solo botón "OK"
    func customAlert(
        isPresented: Binding<Bool>,
        title: LocalizedStringKey,
        message: LocalizedStringKey? = nil
    ) -> some View {
        customAlert(
            isPresented: isPresented,
            title: title,
            message: message,
            buttons: [AlertButton(title: "OK", action: {})] // Botón OK por defecto
        )
    }
}

