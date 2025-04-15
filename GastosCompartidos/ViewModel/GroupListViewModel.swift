//
//  GrupoViewModel.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI // Necesario para @Observable si no usas Combine explícito
import SwiftData

@Observable // El nuevo macro de observación
class GroupListViewModel {
   
    func addGroup(name: String, context: ModelContext) {
        guard !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("Error: El nombre del grupo no puede estar vacío.")
            // Podrías añadir manejo de errores para mostrar al usuario
            return
        }
        let newGroup = Group(name: name)
        context.insert(newGroup)
        // SwiftData guarda automáticamente (o en el momento adecuado según la configuración)
        print("Grupo '\(name)' añadido.")
    }

    // Lógica para borrar grupos (recibe el índice del set para @Query)
    func deleteGroup(at offsets: IndexSet, for groups: [Group], context: ModelContext) {
        offsets.forEach { index in
            let groupToDelete = groups[index]
            context.delete(groupToDelete)
            print("Grupo '\(groupToDelete.name)' eliminado.")
        }
        // SwiftData maneja el guardado
    }

     // Lógica para borrar un grupo específico (alternativa)
    func deleteGroup(_ group: Group, context: ModelContext) {
        context.delete(group)
        print("Grupo '\(group.name)' eliminado.")
    }
}

