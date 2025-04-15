//
//  AddGroupView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI

struct AddGroupView: View {
    @State private var groupName: String = ""
    var onAdd: (String) -> Void // Closure para devolver el nombre al GroupListViewModel
    @Environment(\.dismiss) var dismiss // Para cerrar la hoja modal

    var body: some View {
        NavigationStack { // Usar NavigationStack permite tener título y botones de barra
            Form {
                TextField("Nombre del Grupo", text: $groupName)
                    .autocorrectionDisabled() // Opcional: deshabilitar autocorrección
            }
            .navigationTitle("Nuevo Grupo")
            .navigationBarTitleDisplayMode(.inline) // Título más compacto
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss() // Cierra la hoja
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Añadir") {
                        if !groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onAdd(groupName) // Llama al closure con el nombre
                            dismiss() // Cierra la hoja
                        }
                    }
                    // Deshabilitar el botón si el nombre está vacío (después de quitar espacios)
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    // Proporcionar una implementación vacía para el closure en la preview
    AddGroupView(onAdd: { name in print("Adding group: \(name)") })
}
