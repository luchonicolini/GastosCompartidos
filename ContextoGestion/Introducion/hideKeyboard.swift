//
//  hideKeyboard.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 30/05/2025.
//

import SwiftUI
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
