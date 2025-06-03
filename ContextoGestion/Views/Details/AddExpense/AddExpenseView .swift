//
//  AddExpenseView .swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 30/05/2025.
//

import SwiftUI

extension AddExpenseView {

    func toggleParticipantSelection(_ memberId: UUID) { // Cambiado a internal
        if viewModel.selectedParticipantIds.contains(memberId) {
            viewModel.selectedParticipantIds.remove(memberId)
            if viewModel.selectedSplitType != .equally {
                viewModel.splitInputValues.removeValue(forKey: memberId)
            }
        } else {
            viewModel.selectedParticipantIds.insert(memberId)
        }
    }
    
    func splitInputPlaceholder() -> String { // Cambiado a internal
        switch viewModel.selectedSplitType {
        case .byAmount: return "Monto"
        case .byPercentage: return "%"
        case .byShares: return "Partes"
        case .equally: return ""
        }
    }
    
    func splitInputBinding(for participantId: UUID) -> Binding<String> { // Cambiado a internal
        Binding<String>(
            get: { viewModel.splitInputValues[participantId] ?? "" },
            set: { newValue in
                let filtered = newValue.filter { "0123456789.,".contains($0) }
                let standardized = filtered.replacingOccurrences(of: ",", with: ".")
                let components = standardized.components(separatedBy: ".")
                if components.count <= 2 {
                    viewModel.splitInputValues[participantId] = standardized
                } else {
                    if let existingValue = viewModel.splitInputValues[participantId] {
                        viewModel.splitInputValues[participantId] = String(existingValue)
                    }
                }
            }
        )
    }
    
    func splitInputSumInfo() -> String? { // Cambiado a internal
        guard viewModel.selectedSplitType != .equally else { return nil }
        let relevantValues = viewModel.selectedParticipantIds.compactMap { id in
            viewModel.splitInputValues[id]
        }
        guard !relevantValues.isEmpty else { return "Total: 0" }
        var sum: Double = 0
        for stringValue in relevantValues {
            if let number = numberFormatter.number(from: stringValue) { // Accede a numberFormatter de la struct principal
                sum += number.doubleValue
            } else if !stringValue.isEmpty {
                return "Valor inválido detectado"
            }
        }
        let formattedSum = String(format: "%.2f", sum)
        switch viewModel.selectedSplitType {
        case .byAmount: return "Suma: \(formattedSum)"
        case .byPercentage: return "Suma: \(formattedSum)%"
        case .byShares: return "Total Partes: \(formattedSum)"
        case .equally: return nil
        }
    }
}
