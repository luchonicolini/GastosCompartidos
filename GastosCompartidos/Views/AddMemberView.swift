//
//  AddMemberView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//


// Views/AddMemberView.swift
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
            // <<--- LLAMADA A LA FUNCIÓN DE PRINTS --->>
            // Usamos una función para evitar ensuciar el body directamente
            // La asignación a _ evita warnings de "resultado no usado"
            let _ = printDebuggingInfo()
            // <<--- FIN DE LA LLAMADA --->>

            List {
                // Sección para añadir nueva persona
                Section("Añadir nueva persona") {
                    HStack {
                        TextField("Nombre", text: $newPersonName)
                        Button {
                            addNewPerson()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        .disabled(newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(.borderless)
                    }
                }

                // Lista de personas existentes disponibles
                // Usamos la variable calculada una vez para eficiencia y prints
                let currentAvailablePeople = availablePeople // Calcula una vez
                if !currentAvailablePeople.isEmpty {
                    Section {
                        Text("Puedes añadir personas de otros grupos o crear una nueva arriba.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Section("Añadir persona existente") {
                        // Asegúrate de usar la variable que calculaste
                        ForEach(currentAvailablePeople) { person in
                            Button {
                                addExistingPerson(person)
                            } label: {
                                Text(person.name)
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    // Sección informativa si no hay nadie más para añadir
                    Section {
                        if allPeople.count > (group.members?.count ?? 0) {
                            Text("Todas las personas guardadas ya están en este grupo. Puedes añadir una nueva arriba.")
                                .foregroundStyle(.secondary)
                        } else {
                            Text("No hay otras personas guardadas en la app. Puedes añadir una nueva arriba.")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Añadir Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { dismiss() }
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    // --- Función para Imprimir Información de Depuración ---
    private func printDebuggingInfo() {
        // Calcula availablePeople una vez para los prints
        let currentAvailablePeople = availablePeople

        print("--- AddMemberView Body ---")
        print("Grupo actual: \(group.name)")
        // Añadimos IDs para depurar mejor
        print("Miembros en grupo actual (\(group.members?.count ?? 0)): \(group.members?.map { "\($0.name) (\($0.id))" } ?? ["Ninguno"])")
        // Añadimos IDs para depurar mejor
        print("Total Personas en BD (@Query: \(allPeople.count)): \(allPeople.map { "\($0.name) (\($0.id))" })")
         // Añadimos IDs para depurar mejor
        print("Personas disponibles calculadas (\(currentAvailablePeople.count)): \(currentAvailablePeople.map { "\($0.name) (\($0.id))" })")
        print("--------------------------")
    }


    // --- Funciones de Acción (sin cambios) ---
    private func addExistingPerson(_ person: Person) {
        viewModel.addMember(person, to: group, context: modelContext)
    }

    private func addNewPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        viewModel.addNewPersonAndAddToGroup(name: trimmedName, to: group, context: modelContext)
        newPersonName = ""
    }
}

// --- Preview (sin cambios) ---
#Preview {
    // ... (código del preview sin cambios) ...
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

        return AddMemberView(group: group)
            .modelContainer(container)

    } catch {
        fatalError("Failed to create model container for preview: \(error)")
    }
}

