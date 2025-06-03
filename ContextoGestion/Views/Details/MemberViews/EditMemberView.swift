//
//  EditMemberView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//


// Views/EditMemberView.swift
//
//  EditMemberView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

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
    
    // Estados para animaciones
    @State private var isEditing = false
    @FocusState private var isTextFieldFocused: Bool
    
    init(person: Person, viewModel: GroupDetailViewModel) {
        self.personToEdit = person
        _viewModel = State(initialValue: viewModel)
        _editedName = State(initialValue: person.name)
    }
    
    private var hasChanges: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editedName.trimmingCharacters(in: .whitespacesAndNewlines) != personToEdit.name
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Header con avatar y contexto
                    headerSection
                    
                    // Formulario principal
                    mainFormSection
                    
                    // Información adicional
                    infoSection
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 16)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground", bundle: nil).opacity(0.5),
                        Color("AppBackground", bundle: nil)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Editar Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            dismiss()
                        }
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
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
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            dismiss()
                        }
                    })
                ]
            )
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).delay(0.1)) {
                    isEditing = true
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Avatar del usuario
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.6), Color.purple.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                
                Text(String(personToEdit.name.prefix(2).uppercased()))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .scaleEffect(isEditing ? 1.0 : 0.8)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isEditing)
            
            // Nombre actual
            VStack(spacing: 4) {
                Text("Editando")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1)
                
                Text(personToEdit.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .opacity(isEditing ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.5).delay(0.2), value: isEditing)
        }
        .padding(.top, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Main Form Section
    private var mainFormSection: some View {
        VStack(spacing: 20) {
            // Campo de texto mejorado
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "person.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 16, weight: .medium))
                    
                    Text("Nuevo Nombre")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !editedName.isEmpty && editedName != personToEdit.name {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                TextField("Ingresa el nuevo nombre", text: $editedName)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        isTextFieldFocused ? Color.blue.opacity(0.5) : Color.gray.opacity(0.2),
                                        lineWidth: isTextFieldFocused ? 2 : 1
                                    )
                            )
                    )
                    .focused($isTextFieldFocused)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .animation(.easeInOut(duration: 0.2), value: isTextFieldFocused)
            }
            .padding(.horizontal, 4)
            
            // Indicador de caracteres
            if !editedName.isEmpty {
                HStack {
                    Spacer()
                    Text("\(editedName.count) caracteres")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.trailing, 4)
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground).opacity(0.5))
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                )
        )
        .scaleEffect(isEditing ? 1.0 : 0.95)
        .opacity(isEditing ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: isEditing)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 14))
                
                Text("Los cambios se aplicarán globalmente")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            
            Text("Este miembro aparece en otros grupos y gastos. Al cambiar el nombre, se actualizará en toda la aplicación.")
                .font(.caption2)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.leading, 24)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.top, 20)
        .opacity(isEditing ? 1.0 : 0.0)
        .animation(.easeInOut(duration: 0.5).delay(0.4), value: isEditing)
    }
    
    // MARK: - Save Button
    private var saveButton: some View {
        Button("Guardar") {
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    saveChanges()
                }
            }
        }
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(.primary)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
//
        .scaleEffect(hasChanges ? 1.0 : 0.95)
        .disabled(!hasChanges)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: hasChanges)
    }
    
    // MARK: - Save Function
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
    sampleGroup.members = [samplePerson]
    
    container.mainContext.insert(samplePerson)
    container.mainContext.insert(sampleGroup)
    
    let previewViewModel = GroupDetailViewModel()
    MainActor.assumeIsolated { previewViewModel.setGroup(sampleGroup) }
    
    return EditMemberView(person: samplePerson, viewModel: previewViewModel)
        .modelContainer(container)
}
