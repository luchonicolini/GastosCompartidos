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
    
    let group: Group
    let viewModel: GroupDetailViewModel
    
    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var newPersonName: String = ""
    @State private var searchText: String = ""
    
    @State private var showingErrorAlert = false
    @State private var alertMessage: String = ""
    
    @State private var showingSuccessAlert = false
    @State private var successMessage: String = ""
    
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
                            .onChange(of: newPersonName) { oldValue, newValue in
                                let allowedCharacters = CharacterSet.letters.union(.whitespaces)
                                let filtered = newValue.unicodeScalars.filter { allowedCharacters.contains($0) }
                                let filteredString = String(String.UnicodeScalarView(filtered))
                                if filteredString != newValue {
                                    newPersonName = filteredString
                                }
                            }
                            .autocorrectionDisabled()
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
                                        .foregroundStyle(Color.primary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Text("Escribe un nombre en la barra de búsqueda para encontrar personas existentes y añadirlas.")
                            .font(.caption)
                            .foregroundStyle(Color.secondary)
                    }
                }
                
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            
            .navigationTitle("Añadir Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar persona existente...")
            .autocorrectionDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            // ---- Alerta Personalizada para ERRORES ----
            .customAlert(
                isPresented: $showingErrorAlert,
                title: "Error",
                message: LocalizedStringKey(alertMessage)
            )
            // ---- Alerta Personalizada para ÉXITO ----
            .customAlert(
                isPresented: $showingSuccessAlert,
                title: "Éxito",
                message: LocalizedStringKey(successMessage)
                
            )
            
        }
    }
    
    // --- Funciones de Acción Adaptadas (con Éxito y Error) ---
    
    @MainActor
    private func addExistingPerson(_ person: Person) {
        do {
            try viewModel.addMember(person, to: group, context: modelContext)
            print("Miembro existente '\(person.name)' añadido.")
            searchText = ""
            // Prepara y muestra la alerta de ÉXITO
            self.successMessage = "\(person.name) se añadió al grupo con éxito."
            self.showingSuccessAlert = true
            
        } catch let error as LocalizedError {
            // Configura y muestra la alerta de ERROR
            self.alertMessage = error.errorDescription ?? "No se pudo añadir a la persona."
            self.showingErrorAlert = true
            print("Error al añadir miembro existente: \(error.localizedDescription)")
        } catch {
            // Configura y muestra la alerta de ERROR genérico
            self.alertMessage = "Ocurrió un error inesperado al añadir a la persona."
            self.showingErrorAlert = true
            print("Error inesperado: \(error)")
        }
    }
    
    @MainActor
    private func addNewPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        do {
            try viewModel.addNewPersonAndAddToGroup(name: trimmedName, to: group, context: modelContext)
            print("Nueva persona '\(trimmedName)' creada y añadida.")
            // Prepara y muestra la alerta de ÉXITO
            self.successMessage = "\(trimmedName) se añadió al grupo con éxito."
            self.showingSuccessAlert = true
            newPersonName = "" // Limpia el campo después del éxito
            
        } catch let error as LocalizedError {
            // Configura y muestra la alerta de ERROR
            self.alertMessage = error.errorDescription ?? "No se pudo añadir la nueva persona."
            self.showingErrorAlert = true
            print("Error al añadir nueva persona: \(error.localizedDescription)")
        } catch {
            // Configura y muestra la alerta de ERROR genérico
            self.alertMessage = "Ocurrió un error inesperado al añadir la nueva persona."
            self.showingErrorAlert = true
            print("Error inesperado: \(error)")
        }
    }
}


#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
    let p1 = Person(name: "Juan")
    let group = Group(name: "Grupo Prueba")
    group.members = [p1]
    container.mainContext.insert(p1)
    container.mainContext.insert(group)
    let vm = GroupDetailViewModel()
    MainActor.assumeIsolated { vm.setGroup(group) }
    
    return AddMemberView(group: group, viewModel: vm)
        .modelContainer(container)
}

