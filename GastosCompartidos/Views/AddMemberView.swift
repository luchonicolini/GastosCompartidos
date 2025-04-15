//
//  AddMemberView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//


import SwiftUI
import SwiftData

struct AddMemberView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    // El grupo al que estamos añadiendo miembros
    let group: Group

    // ViewModel para la lógica de añadir/crear
    @State private var viewModel = GroupDetailViewModel()

    // Consulta para obtener TODAS las personas guardadas en la app
    @Query(sort: \Person.name) private var allPeople: [Person]

    // Estado para el campo de texto de nueva persona
    @State private var newPersonName: String = ""

    // Calculamos quiénes NO están ya en el grupo
    private var availablePeople: [Person] {
        let groupMemberIDs = Set(group.members?.map { $0.id } ?? [])
        return allPeople.filter { !groupMemberIDs.contains($0.id) }
    }

    var body: some View {
        NavigationStack {
            // Usar List directamente para mejor integración con Form/Section si es necesario
            List {
                // Sección para añadir nueva persona
                Section("Añadir nueva persona") {
                    HStack {
                        TextField("Nombre", text: $newPersonName)
                            // .textFieldStyle(.roundedBorder) // No necesario dentro de List/Form
                        Button {
                            addNewPerson()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24) // Ajustar tamaño icono
                        }
                        .disabled(newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderless) // Evitar estilo por defecto en List
                    }
                }

                // Lista de personas existentes disponibles
                if availablePeople.isEmpty && allPeople.count > (group.members?.count ?? 0) {
                    // Caso donde hay otras personas pero ya están todas en este grupo
                     Section("Añadir persona existente") {
                        Text("Todas las personas guardadas ya están en este grupo.")
                            .foregroundStyle(.secondary)
                    }
                } else if availablePeople.isEmpty && allPeople.count <= (group.members?.count ?? 0) {
                     // Caso donde no hay otras personas en la app
                     Section("Añadir persona existente") {
                        Text("No hay otras personas guardadas en la app.")
                            .foregroundStyle(.secondary)
                    }
                }
                else {
                    Section("Añadir persona existente") {
                        ForEach(availablePeople) { person in
                            Button {
                                addExistingPerson(person)
                            } label: {
                                Text(person.name)
                                    .foregroundStyle(.primary) // Asegurar color de texto
                                    .frame(maxWidth: .infinity, alignment: .leading) // Ocupar espacio
                            }
                            .buttonStyle(.plain) // Estilo limpio para botones en lista
                        }
                    }
                }
            }
            // .listStyle(.insetGrouped) // Puedes elegir el estilo de lista
            .navigationTitle("Añadir Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            // Ocultar teclado al hacer scroll en la lista (opcional)
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // --- Funciones de Acción ---
    private func addExistingPerson(_ person: Person) {
        viewModel.addMember(person, to: group, context: modelContext)
        // dismiss() // Podrías cerrar al añadir, o permitir añadir varios
    }

    private func addNewPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        viewModel.addNewPersonAndAddToGroup(name: trimmedName, to: group, context: modelContext)
        newPersonName = "" // Limpiar campo
        // dismiss() // Podrías cerrar al añadir, o permitir añadir varios
    }
}

// --- Preview ---
#Preview {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
        let p1 = Person(name: "Ana") // Ya en el grupo
        let p2 = Person(name: "Juan") // No en el grupo
        let p3 = Person(name: "Pedro") // No en el grupo
        let group = Group(name: "Grupo AddMember Preview")
        group.members = [p1]
        container.mainContext.insert(p1)
        container.mainContext.insert(p2)
        container.mainContext.insert(p3)
        container.mainContext.insert(group)

        // Importante: Pasar el grupo a la vista
        return AddMemberView(group: group)
            .modelContainer(container) // Pasar el contenedor a la preview

    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}


