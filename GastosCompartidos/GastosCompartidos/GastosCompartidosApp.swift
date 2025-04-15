//
//  GastosCompartidosApp.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//

import SwiftUI
import SwiftData

@main
struct GastosCompartidosApp: App {

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Group.self,
            Person.self,
            Expense.self
            // Asegúrate que estos nombres coincidan con tus clases @Model
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            GroupListView() // Tu vista inicial
        }
        .modelContainer(sharedModelContainer)
    }
}
