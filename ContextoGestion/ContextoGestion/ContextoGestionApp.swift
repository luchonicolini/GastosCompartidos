//
//  ContextoGestionApp.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

@main
struct ContextoGestionApp: App {
    init() {
           ReviewHandler.shared.incrementAppLaunchCount()
           print("App Launch Count: \(UserDefaults.standard.integer(forKey: "appLaunchCount_ContextoGestion"))")
       }
    let container: ModelContainer = {
        let schema = Schema([
            Group.self,
            Person.self,
            Expense.self
        ])
        let config = ModelConfiguration("GastosPruebaDB", schema: schema)
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("No se pudo crear el ModelContainer: \(error)")
        }
    }()
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
