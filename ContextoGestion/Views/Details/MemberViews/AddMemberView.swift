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
    
    let group: Group // El grupo al que se añaden miembros
    let viewModel: GroupDetailViewModel
    
    @Query(sort: \Person.name) private var allPeople: [Person]
    @State private var newPersonName: String = ""
    @State private var searchText: String = ""
    
    @State private var showingErrorAlert = false
    @State private var alertMessage: String = ""
    
    @State private var showingSuccessAlert = false
    @State private var successMessage: String = ""
    
    private var currentMemberCount: Int {
        group.members?.count ?? 0
    }
    
    private var memberCountText: String {
        "Actualmente hay \(currentMemberCount) \(currentMemberCount == 1 ? "miembro" : "miembros") en este grupo."
    }

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
          
            VStack(spacing: 0) {
                // --- CONTADOR DE MIEMBROS ---
                Text(memberCountText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .center)
      
                // --- FIN CONTADOR DE MIEMBROS ---
                
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
                // El .listStyle se puede ajustar si es necesario
                // .listStyle(.insetGrouped) o .plain
            }
            .scrollContentBackground(.hidden) // Si usas List, esto ayuda con el fondo de la lista
            .background(Color("AppBackground")) // Fondo general de la vista
            .navigationTitle("Añadir Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar persona existente...")
            .autocorrectionDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .customAlert(
                isPresented: $showingErrorAlert,
                title: "Error",
                message: LocalizedStringKey(alertMessage)
            )
            .customAlert(
                isPresented: $showingSuccessAlert,
                title: "Éxito",
                message: LocalizedStringKey(successMessage)
            )
        }
    }
    
    @MainActor
    private func addExistingPerson(_ person: Person) {
        do {
            try viewModel.addMember(person, to: group, context: modelContext)
            self.successMessage = "\(person.name) se añadió al grupo con éxito."
            self.showingSuccessAlert = true
            searchText = "" // Limpiar búsqueda tras añadir
        } catch let error as LocalizedError {
            self.alertMessage = error.errorDescription ?? "No se pudo añadir a la persona."
            self.showingErrorAlert = true
        } catch {
            self.alertMessage = "Ocurrió un error inesperado al añadir a la persona."
            self.showingErrorAlert = true
        }
    }
    
    @MainActor
    private func addNewPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        do {
            try viewModel.addNewPersonAndAddToGroup(name: trimmedName, to: group, context: modelContext)
            self.successMessage = "\(trimmedName) se añadió al grupo con éxito."
            self.showingSuccessAlert = true
            newPersonName = ""
        } catch let error as LocalizedError {
            self.alertMessage = error.errorDescription ?? "No se pudo añadir la nueva persona."
            self.showingErrorAlert = true
        } catch {
            self.alertMessage = "Ocurrió un error inesperado al añadir la nueva persona."
            self.showingErrorAlert = true
        }
    }
}

// --- Vista Previa (Preview) ---
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
    
    let p1 = Person(name: "Juan Existente")
    let p2 = Person(name: "Ana Miembro")
    let groupConMiembros = Group(name: "Grupo con Miembros")
    groupConMiembros.members = [p2] // Ana ya es miembro
    
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(groupConMiembros)
    
    let vm = GroupDetailViewModel()
    // Es importante establecer el grupo en el ViewModel para que las acciones de añadir funcionen correctamente
    // y para que el conteo de miembros sea preciso para el preview (si viewModel lo usara para eso)
    // MainActor.assumeIsolated { vm.setGroup(groupConMiembros) } // No es estrictamente necesario para el contador aquí si group.members se usa directo

    // Para probar el contador con diferentes números de miembros:
    let groupVacio = Group(name: "Grupo Vacío")
    container.mainContext.insert(groupVacio)

    return AddMemberView(group: groupConMiembros, viewModel: vm) // Probar con el grupo que tiene 1 miembro
    // return AddMemberView(group: groupVacio, viewModel: vm) // Probar con el grupo que tiene 0 miembros
        .modelContainer(container)
}

