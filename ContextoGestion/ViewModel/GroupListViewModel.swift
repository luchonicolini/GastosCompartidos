//
//  GroupListViewModel.swift
//  GastosPrueba
//
//  Created by Luciano Nicolini on 16/04/2025.
//

import SwiftData
import Observation
import Foundation

@Observable
class GroupListViewModel {

    func addGroup(name: String, iconName: String?, colorHex: String?, context: ModelContext) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw GroupError.emptyName
        }

        let newGroup = Group(name: trimmedName, iconName: iconName, colorHex: colorHex)
        context.insert(newGroup)
        do {
            // Aunque SwiftData a menudo guarda implícitamente, un save aquí puede
            // asegurar que el error se capture si ocurre en este punto.
            try context.save()
        } catch {
            print("Database Save Error on addGroup: \(error.localizedDescription)")
            context.delete(newGroup) // Intenta revertir la inserción si falla el guardado
            throw GroupError.databaseSaveError(error)
        }
    }

    func updateGroup(group: Group, name: String, iconName: String?, colorHex: String?, context: ModelContext) throws {
         let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
         guard !trimmedName.isEmpty else {
             throw GroupError.emptyName
         }
         group.name = trimmedName
         group.iconName = iconName
         group.colorHex = colorHex
         // Las actualizaciones de propiedades en objetos existentes suelen guardarse
         // automáticamente por SwiftData cuando el contexto detecta cambios.
         // Un context.save() explícito aquí generalmente no es necesario a menos
         // que se necesite control transaccional o manejo inmediato de errores de guardado.
    }


    func deleteGroup(at offsets: IndexSet, for groups: [Group], context: ModelContext) {
        offsets.forEach { index in
            if index < groups.count {
                let groupToDelete = groups[index]
                context.delete(groupToDelete)
                 // SwiftData maneja la regla de borrado en cascada para gastos
            }
        }
         // El guardado suele ser implícito, pero un save() podría forzarlo si es necesario.
    }

    func deleteGroup(_ group: Group, context: ModelContext) {
        context.delete(group)
    }
}
