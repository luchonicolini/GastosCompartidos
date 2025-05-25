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
    let personToEdit: Person
    @State var viewModel: GroupDetailViewModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @State private var editedName: String

    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    @State private var showingSuccessAlert = false
    @State private var successMessage = ""

    init(person: Person, viewModel: GroupDetailViewModel) {
        self.personToEdit = person
        _viewModel = State(initialValue: viewModel)
        _editedName = State(initialValue: person.name)
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Nombre", text: $editedName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Nombre del Miembro")
                } footer: {
                    Text("Estás editando el nombre de '\(personToEdit.name)'. Los cambios se guardarán para este miembro en toda la aplicación.")
                        .font(.caption)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color("AppBackground"))
            .navigationTitle("Editar Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") { saveChanges() }
                        .disabled(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedName == personToEdit.name)
                        .fontWeight(.bold)
                        // Considera aplicar un .tint() aquí si estás usando colores de acento personalizados
                         .tint( (editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || editedName == personToEdit.name) ? .gray : .green )
                }
            }
            .customAlert(
                isPresented: $showingErrorAlert,
                title: "Error al Actualizar",
                message: LocalizedStringKey(alertMessage)
            )
            .customAlert(
                isPresented: $showingSuccessAlert,
                title: "Éxito",
                message: LocalizedStringKey(successMessage),
                buttons: [
                    AlertButton(title: "OK", action: {
                        dismiss()
                    })
                ]
            )
        }
    }

    @MainActor private func saveChanges() {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            self.alertMessage = "El nombre no puede estar vacío."
            self.showingErrorAlert = true
            return
        }

        do {
            try viewModel.updatePerson(person: personToEdit, name: trimmedName, context: modelContext)
            self.successMessage = "Nombre cambiado a '\(trimmedName)' con éxito."
            self.showingSuccessAlert = true
        } catch let error as PersonError {
             self.alertMessage = error.localizedDescription
             self.showingErrorAlert = true
        } catch {
             self.alertMessage = "Ocurrió un error inesperado al guardar los cambios."
             self.showingErrorAlert = true
        }
    }
}

#Preview {
     let config = ModelConfiguration(isStoredInMemoryOnly: true)
     let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
     
     let samplePerson = Person(name: "Nombre Original Para Editar")
     let sampleGroup = Group(name: "Grupo de Prueba para ViewModel")
     sampleGroup.members = [samplePerson] // Asegurarse que el miembro pertenezca a un grupo para el contexto del VM
     
     container.mainContext.insert(samplePerson)
     container.mainContext.insert(sampleGroup)
     
     let previewViewModel = GroupDetailViewModel()
     // Es importante que el viewModel se configure con un grupo que contenga al miembro
     // para que la lógica de `updatePerson` (especialmente el guard) funcione como se espera.
     MainActor.assumeIsolated { previewViewModel.setGroup(sampleGroup) }

     return EditMemberView(person: samplePerson, viewModel: previewViewModel)
            .modelContainer(container)
}
