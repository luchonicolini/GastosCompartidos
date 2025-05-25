//
//  CustomButton.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 19/05/2025.
//

import SwiftUI

struct CustomButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    let height: CGFloat = 60
    let fontStyle: Font = .system(size: 20, weight: .semibold, design: .rounded)
    
    var offsetY: CGFloat {
        isPressed ? 0 : -8
    }
    
    @State private var isPressed = false
    @State private var hapticTrigger = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(color.opacity(0.7))
                .frame(height: height)
            
            RoundedRectangle(cornerRadius: 16)
                .foregroundStyle(color)
                .frame(height: height)
                .offset(y: offsetY)
                .overlay {
                    Text(title)
                        .foregroundStyle(.white)
                        .font(fontStyle)
                        .offset(y: offsetY)
                }
                .onTapGesture {
                    hapticTrigger.toggle()
                    action()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            withAnimation(.spring(.snappy(duration: 0.05))) {
                                isPressed = true
                            }
                        }
                        .onEnded { _ in
                            withAnimation(.spring(.snappy(duration: 0.05))) {
                                isPressed = false
                            }
                        }
                )
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    CustomButton(title: "hola mundo", color: .green, action: {
        print("Botón presionado")
    })
    .padding()
}
