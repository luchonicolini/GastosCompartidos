//
//  Colors.swift
//  GastosPrueba
//
//  Created by Luciano Nicolini on 20/04/2025.
//

import Foundation
// Utils/Color+Hex.swift

import SwiftUI
#if canImport(UIKit)
import UIKit // Para iOS/iPadOS/tvOS/watchOS
#elseif canImport(AppKit)
import AppKit // Para macOS
#endif

extension Color {
    // Inicializador para crear un Color desde un String Hex (#RRGGBB o #AARRGGBB)
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 1.0 // Alfa por defecto

        let length = hexSanitized.count

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        if length == 6 { // #RRGGBB
            r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x0000FF) / 255.0
        } else if length == 8 { // #AARRGGBB
            a = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            r = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            g = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            b = CGFloat(rgb & 0x000000FF) / 255.0
        } else {
            // Formato inválido
            return nil
        }

        self.init(red: r, green: g, blue: b, opacity: a)
    }

    // Función para convertir un Color a un String Hex (#RRGGBB)
    // Nota: Puede perder información de espacio de color y opacidad exacta en algunos casos.
    func toHex() -> String? {
        #if canImport(UIKit)
        typealias NativeColor = UIColor
        #elseif canImport(AppKit)
        typealias NativeColor = NSColor
        #else
        // Plataforma no soportada para obtener componentes directamente
        return nil
        #endif

        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        // Intentar obtener componentes RGBA del color nativo subyacente
        guard NativeColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else {
            // No se pudieron obtener componentes (ej. color Clear, o no basado en RGB)
            return nil
        }

        // Convertir componentes (0.0-1.0) a enteros (0-255) y formatear
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

        return String(format: "#%06x", rgb).uppercased()
    }
}
