//
//  AddMemberView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

struct AddMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    
    // Recibe el grupo al que se añadirán miembros
    let group: Group
    //@State private var viewModel = GroupDetailViewModel()
    let viewModel: GroupDetailViewModel
    
    // Query para buscar entre TODAS las personas existentes en la app
    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var newPersonName: String = ""
    @State private var searchText: String = ""
    
    // Estados para manejar alertas de error
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""
    
    // Personas filtradas por búsqueda que NO están ya en el grupo
    private var searchResults: [Person] {
        guard !searchText.isEmpty else { return [] }
        
        let groupMemberIDs = Set(group.members?.map { $0.id } ?? [])
        let lowercasedSearch = searchText.lowercased()
        
        return allPeople.filter { person in
            !groupMemberIDs.contains(person.id) &&
            person.name.lowercased().contains(lowercasedSearch)
        }
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section("Añadir nueva persona") {
                    HStack {
                        TextField("Nombre", text: $newPersonName)
                        Button {
                            addNewPerson()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable().frame(width: 24, height: 24)
                                .foregroundStyle(.green)
                        }
                        .disabled(newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderless)
                    }
                }
                
                // --- Sección para Añadir Persona Existente (Resultados de Búsqueda) ---
                Section(searchText.isEmpty ? "Añadir persona existente" : "Resultados de búsqueda") {
                    if !searchText.isEmpty {
                        if searchResults.isEmpty {
                            Text("No se encontraron personas con '\(searchText)' que no estén ya en el grupo.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(searchResults) { person in
                                Button {
                                    addExistingPerson(person)
                                } label: {
                                    Label(person.name, systemImage: "person")
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Text("Escribe un nombre en la barra de búsqueda para encontrar personas existentes y añadirlas.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } // Fin Section Existentes
                
            }
            .navigationTitle("Añadir Miembro a \(group.name)")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar persona existente...")
            .autocorrectionDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            // Alerta para mostrar errores
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
            // --- NUEVO: Alerta para mostrar ÉXITO ---
            .alert("Éxito", isPresented: $showingSuccessAlert) {
                Button("OK") { } // Simplemente cierra la alerta
            } message: {
                Text(successMessage) // Muestra el mensaje de éxito
            }
            
        } // Fin NavigationStack
    }
    
    // --- Funciones de Acción (Adaptadas con do-catch) ---
    
    // Añade una persona existente seleccionada de la búsqueda
    @MainActor // Marcar como MainActor porque llama a VM.addMember que lo es
    private func addExistingPerson(_ person: Person) {
        do {
            try viewModel.addMember(person, to: group, context: modelContext)
            print("Miembro existente '\(person.name)' añadido.")
            searchText = ""
            successMessage = "\(person.name) se añadió al grupo con éxito."
            showingSuccessAlert = true
            
        } catch let error as LocalizedError {
            // Error al añadir: Mostrar alerta
            alertMessage = error.errorDescription ?? "No se pudo añadir a la persona."
            showingErrorAlert = true
            print("Error al añadir miembro existente: \(error.localizedDescription)")
        } catch {
            // Otro error inesperado
            alertMessage = "Ocurrió un error inesperado al añadir a la persona."
            showingErrorAlert = true
            print("Error inesperado: \(error)")
        }
    }
    
    // Crea una nueva persona y la añade al grupo
    @MainActor // Marcar como MainActor porque llama a VM.addNewPersonAndAddToGroup que lo es
    private func addNewPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return } // Ya deshabilitado por botón, pero doble check
        
        do {
            try viewModel.addNewPersonAndAddToGroup(name: trimmedName, to: group, context: modelContext)
            print("Nueva persona '\(trimmedName)' creada y añadida.")
            newPersonName = ""
            
            successMessage = "\(trimmedName) se añadió al grupo con éxito."
                        showingSuccessAlert = true
                        newPersonName = ""
            
        } catch let error as LocalizedError {
            // Error al añadir: Mostrar alerta
            alertMessage = error.errorDescription ?? "No se pudo añadir la nueva persona."
            showingErrorAlert = true
            print("Error al añadir nueva persona: \(error.localizedDescription)")
        } catch {
            // Otro error inesperado
            alertMessage = "Ocurrió un error inesperado al añadir la nueva persona."
            showingErrorAlert = true
            print("Error inesperado: \(error)")
        }
    }
}

// --- Preview

