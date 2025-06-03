//
//  SettlementPayment.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 02/06/2025.
//

//
//  SettlementPayment.swift
//  ContextoGestion
//
//  Created by Assistant on 02/06/2025.
//

import SwiftData
import Foundation

@Model
class SettlementPayment {
    var id: UUID = UUID()
    var payerId: UUID  // ID de quien paga
    var payeeId: UUID  // ID de quien recibe
    var amount: Double // Monto pagado
    var date: Date     // Fecha del pago
    var group: Group?  // Grupo al que pertenece
    var payerName: String  // Nombre del pagador (para referencia)
    var payeeName: String  // Nombre del receptor (para referencia)
    
    init(payerId: UUID, payeeId: UUID, amount: Double, group: Group?, payerName: String, payeeName: String) {
        self.payerId = payerId
        self.payeeId = payeeId
        self.amount = amount
        self.date = Date()
        self.group = group
        self.payerName = payerName
        self.payeeName = payeeName
    }
}
