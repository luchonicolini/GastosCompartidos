//
//  ReviewHandler.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 30/05/2025.
//

import StoreKit
import SwiftUI

class ReviewHandler {
    static let shared = ReviewHandler()
    
    private let minLaunchesBeforePrompt = 5 // Ejemplo: Pedir después de 5 aperturas
    private let minSignificantEventsBeforePrompt = 3 // Ejemplo: Después de 3 acciones importantes

    private var launchCount: Int {
        get { UserDefaults.standard.integer(forKey: "appLaunchCount_ContextoGestion") }
        set { UserDefaults.standard.set(newValue, forKey: "appLaunchCount_ContextoGestion") }
    }

    private var significantEventCount: Int {
        get { UserDefaults.standard.integer(forKey: "significantEventCount_ContextoGestion") }
        set { UserDefaults.standard.set(newValue, forKey: "significantEventCount_ContextoGestion") }
    }
    

    func incrementAppLaunchCount() {
        launchCount += 1
    }

    func logSignificantEvent() {
        significantEventCount += 1
        // Podrías llamar a requestReviewIfNeeded() aquí también si lo deseas
    }

    func requestReviewIfNeeded() {
        guard launchCount >= minLaunchesBeforePrompt || significantEventCount >= minSignificantEventsBeforePrompt else {
            return
        }

        // Encuentra la escena activa de la ventana
        // Necesitas importar UIKit para UIApplication si no lo tienes, o usar una alternativa para windowScene
        // Si estás en SwiftUI puro y tu app es iOS 14+, puedes obtenerlo así:
        guard let currentScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else {
            print("No se pudo obtener la UIWindowScene activa.")
            return
        }
        
        print("Intentando solicitar reseña...")
        SKStoreReviewController.requestReview(in: currentScene)
        
        // Opcional: Resetea tus contadores para que la condición no se cumpla inmediatamente otra vez,
        // o implementa una lógica más avanzada para el siguiente recordatorio.
        // El sistema ya limita la frecuencia, así que resetear agresivamente puede no ser necesario.
        // Por ejemplo, podrías resetear significantEventCount aquí o solo basarte en el límite del sistema.
        // launchCount = 0 // Podrías resetearlo o solo dejar que el sistema decida.
        // significantEventCount = 0
    }
}
