//
//  AllSettledView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 29/05/2025.
//

import SwiftUI

struct AllSettledView: View {
    @State private var isAnimating = false
    @State private var confettiAnimation = false
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Animación de confetti/celebración
            ZStack {
                // Círculo de fondo con gradiente
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.green.opacity(0.3), .mint.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                // Ícono principal
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.spring(response: 0.8, dampingFraction: 0.6)
                            .delay(0.2),
                        value: isAnimating
                    )
                
                // Partículas de celebración
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(Color.random)
                        .frame(width: 8, height: 8)
                        .offset(
                            x: confettiAnimation ? CGFloat.random(in: -100...100) : 0,
                            y: confettiAnimation ? CGFloat.random(in: -100...100) : 0
                        )
                        .opacity(confettiAnimation ? 0 : 1)
                        .animation(
                            Animation.easeOut(duration: 1.5)
                                .delay(Double(index) * 0.1),
                            value: confettiAnimation
                        )
                }
            }
            
            // Texto principal
            VStack(spacing: 16) {
                Text("¡Todo Saldado!")
                    .font(.largeTitle.bold())
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green, .mint],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(isAnimating ? 1.05 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.0)
                            .delay(0.5),
                        value: isAnimating
                    )
                
                Text("¡Excelente trabajo! 🎉")
                    .font(.title2.weight(.medium))
                    .foregroundColor(.primary)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .delay(0.8),
                        value: isAnimating
                    )
                
                Text("No hay deudas pendientes en este grupo.\nTodos están al día con sus pagos.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .opacity(isAnimating ? 1.0 : 0.0)
                    .offset(y: isAnimating ? 0 : 20)
                    .animation(
                        Animation.easeOut(duration: 0.8)
                            .delay(1.0),
                        value: isAnimating
                    )
            }
            
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .onAppear {
            withAnimation {
                isAnimating = true
                pulseAnimation = true
            }
            
            // Confetti animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation {
                    confettiAnimation = true
                }
            }
            
            // Reset confetti para que se pueda repetir
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                confettiAnimation = false
            }
        }
    }
}

// Extensión para colores aleatorios
extension Color {
    static var random: Color {
        return Color(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

// Preview
#Preview("All Settled View") {
    AllSettledView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("AppBackground"))
}
