//
//  EditMemberView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

// Views/EditMemberView.swift
import SwiftUI
import SwiftData

struct EditMemberView: View {
    // La persona que estamos editando (pasada desde la vista anterior)
    let personToEdit: Person

    // Acceso al ViewModel que contiene la lógica de actualización.
    // Asumimos que esta vista se presenta desde un lugar que ya tiene
    // acceso al ViewModel (ej. GroupDetailView).
    @State var viewModel: GroupDetailViewModel

    // Necesitamos el contexto para guardar los cambios a través del ViewModel
    @Environment(\.modelContext) private var modelContext

    // Para poder cerrar la vista (sheet/modal)
    @Environment(\.dismiss) var dismiss

    // Estado local para el nombre editado en el TextField
    @State private var editedName: String

    // Estado para manejar la alerta de error
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Inicializador para configurar el estado inicial del nombre editado
    init(person: Person, viewModel: GroupDetailViewModel) {
        self.personToEdit = person
        self.viewModel = viewModel
        // Inicializa el estado local con el nombre actual de la persona
        _editedName = State(initialValue: person.name)
    }

    var body: some View {
        // Usar NavigationView permite añadir botones de barra de navegación fácilmente
        NavigationView {
            Form {
                Section("Nombre del Miembro") {
                    TextField("Nombre", text: $editedName)
                        .autocorrectionDisabled() // Deshabilitar autocorrección si se desea
                        .textInputAutocapitalization(.words) // Capitalizar nombres automáticamente
                }
            }
            .navigationTitle("Editar Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Botón para cancelar
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss() // Cierra la vista sin guardar
                    }
                }
                // Botón para guardar
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                    }
                    // Deshabilitar el botón si el nombre está vacío o no ha cambiado
                    .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedName == personToEdit.name)
                }
            }
            .alert("Error al Actualizar", isPresented: $showingAlert) {
                Button("OK") { } // Botón simple para cerrar la alerta
            } message: {
                Text(alertMessage) // Muestra el mensaje de error específico
            }
        }
    }

    // Función para manejar el guardado
    @MainActor private func saveChanges() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)

        // Validar que el nombre no esté vacío (aunque el ViewModel también lo hace)
        guard !trimmedName.isEmpty else {
            alertMessage = "El nombre no puede estar vacío."
            showingAlert = true
            return
        }

        do {
            // Llama a la función del ViewModel para actualizar la persona
            // La función updatePerson en el ViewModel se encarga de la lógica
            // incluyendo la validación de nombre vacío y potencialmente guardar.
            try viewModel.updatePerson(person: personToEdit, name: trimmedName, context: modelContext)
            
            // Si todo fue bien, cierra la vista
            dismiss()

        } catch let error as PersonError {
             // Captura errores específicos de Persona lanzados por el ViewModel
             alertMessage = error.localizedDescription // Usa la descripción localizada del error
             showingAlert = true
        } catch {
             // Captura cualquier otro error inesperado
             print("Error inesperado al actualizar persona: \(error)")
             alertMessage = "Ocurrió un error inesperado al guardar los cambios."
             showingAlert = true
        }
    }
}

// --- Vista Previa (Preview) ---
// Similar a BalanceView, necesitarás un contenedor y datos de ejemplo.
#Preview {
    // 1. Configura el contenedor en memoria
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)

    // 2. Crea datos de ejemplo
    let samplePerson = Person(name: "Nombre Original")
    let sampleGroup = Group(name: "Grupo de Prueba") // Necesario para el ViewModel
    sampleGroup.members = [samplePerson] // Añadir la persona al grupo

    container.mainContext.insert(samplePerson)
    container.mainContext.insert(sampleGroup)

    // 3. Crea una instancia del ViewModel (requiere el grupo)
    let previewViewModel = GroupDetailViewModel()
    // Configura el grupo en el ViewModel para la vista previa
    // Usamos MainActor.assumeIsolated para llamar a la función @MainActor desde un contexto no aislado
    MainActor.assumeIsolated {
         previewViewModel.setGroup(sampleGroup)
    }


    // 4. Retorna la vista, pasando la persona y el viewModel
    // Es importante pasar el viewModel ya inicializado
    return EditMemberView(person: samplePerson, viewModel: previewViewModel)
           .modelContainer(container) // Inyecta el contenedor
}
