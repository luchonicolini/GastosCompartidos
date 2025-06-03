//
//  AddMemberView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

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
    @State private var isAddingNew = false
    @State private var isAddingExisting = false
    
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
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: - Header con estadísticas
                    headerStatsCard
                    
                    // MARK: - Sección añadir nueva persona
                    addNewPersonCard
                    
                    // MARK: - Sección búsqueda y resultados
                    if !searchText.isEmpty {
                        searchResultsCard
                    } else {
                        searchPromptCard
                    }
                    
                    // MARK: - Miembros actuales preview
                    if currentMemberCount > 0 {
                        currentMembersCard
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color("AppBackground"),
                        Color("AppBackground").opacity(0.8)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle("Añadir Miembro")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar persona existente..."
            )
            .autocorrectionDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundStyle(.secondary)
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
    
    // MARK: - Header Stats Card
    @ViewBuilder
    private var headerStatsCard: some View {
        VStack(spacing: 12) {
            HStack {
                // Icono del grupo
                ZStack {
                    Circle()
                        .fill(group.displayColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    group.displayIcon
                        .font(.title2)
                        .foregroundStyle(group.displayColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.name)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.primary)
                    
                    Text(memberCountText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Badge con contador
                ZStack {
                    Capsule()
                        .fill(group.displayColor.opacity(0.15))
                        .frame(width: 60, height: 30)
                    
                    Text("\(currentMemberCount)")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(group.displayColor)
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Add New Person Card
    @ViewBuilder
    private var addNewPersonCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundStyle(group.displayColor)
                
                Text("Añadir nueva persona")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                // Campo de texto mejorado
                HStack {
                    Image(systemName: "person")
                        .foregroundStyle(.secondary)
                        .frame(width: 20)
                    
                    TextField("Nombre completo", text: $newPersonName)
                        .onChange(of: newPersonName) { oldValue, newValue in
                            let allowedCharacters = CharacterSet.letters.union(.whitespaces)
                            let filtered = newValue.unicodeScalars.filter { allowedCharacters.contains($0) }
                            let filteredString = String(String.UnicodeScalarView(filtered))
                            if filteredString != newValue {
                                newPersonName = filteredString
                            }
                        }
                        .autocorrectionDisabled()
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.white.opacity(0.2), lineWidth: 1)
                )
                
                // Botón añadir mejorado
                Button {
                    Task { // <--- ENVUELVE EN UN TASK
                        await addNewPerson()
                        }
                } label: {
                    ZStack {
                        if isAddingNew {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(
                        newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? Color.gray.opacity(0.3)
                        : group.displayColor,
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .disabled(newPersonName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isAddingNew)
                .animation(.easeInOut(duration: 0.2), value: isAddingNew)
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Search Results Card
    @ViewBuilder
    private var searchResultsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                Text("Resultados de búsqueda")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !searchResults.isEmpty {
                    Text("\(searchResults.count)")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.15), in: Capsule())
                        .foregroundStyle(.blue)
                }
            }
            
            if searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    
                    Text("No se encontraron personas")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    
                    Text("No hay personas con '\(searchText)' que no estén ya en el grupo")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(searchResults) { person in
                        personResultRow(person)
                    }
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Search Prompt Card
    @ViewBuilder
    private var searchPromptCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 48))
                .foregroundStyle(.blue.opacity(0.6))
            
            Text("Buscar personas existentes")
                .font(.headline.weight(.medium))
                .foregroundStyle(.primary)
            
            Text("Usa la barra de búsqueda arriba para encontrar personas ya registradas y añadirlas al grupo")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Current Members Preview Card
    @ViewBuilder
    private var currentMembersCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "person.2")
                    .font(.title2)
                    .foregroundStyle(group.displayColor)
                
                Text("Miembros actuales")
                    .font(.headline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
            }
            
            LazyVStack(spacing: 8) {
                ForEach(group.members ?? []) { member in
                    HStack {
                        // Avatar inicial del nombre
                        ZStack {
                            Circle()
                                .fill(group.displayColor.opacity(0.2))
                                .frame(width: 32, height: 32)
                            
                            Text(String(member.name.prefix(1)).uppercased())
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(group.displayColor)
                        }
                        
                        Text(member.name)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.green.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Person Result Row
    @ViewBuilder
    private func personResultRow(_ person: Person) -> some View {
        Button {
            Task { // <--- ENVUELVE EN UN TASK
                await addExistingPerson(person)
                }
        } label: {
            HStack {
                // Avatar inicial del nombre
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 36, height: 36)
                    
                    Text(String(person.name.prefix(1)).uppercased())
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.blue)
                }
                
                Text(person.name)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                
                Spacer()
                
                ZStack {
                    if isAddingExisting {
                        ProgressView()
                            .scaleEffect(0.7)
                            .tint(.blue)
                    } else {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 20))
                            .foregroundStyle(.blue)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.blue.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.blue.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(isAddingExisting)
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func addExistingPerson(_ person: Person) {
        isAddingExisting = true
        
        do {
            try viewModel.addMember(person, to: group, context: modelContext)
            self.successMessage = "\(person.name) se añadió al grupo con éxito."
            self.showingSuccessAlert = true
            searchText = ""
            
            // Feedback háptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch let error as LocalizedError {
            self.alertMessage = error.errorDescription ?? "No se pudo añadir a la persona."
            self.showingErrorAlert = true
        } catch {
            self.alertMessage = "Ocurrió un error inesperado al añadir a la persona."
            self.showingErrorAlert = true
        }
        
        isAddingExisting = false
    }
    
    @MainActor
    private func addNewPerson() {
        let trimmedName = newPersonName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        isAddingNew = true
        
        do {
            try viewModel.addNewPersonAndAddToGroup(name: trimmedName, to: group, context: modelContext)
            self.successMessage = "\(trimmedName) se añadió al grupo con éxito."
            self.showingSuccessAlert = true
            newPersonName = ""
            
            // Feedback háptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
        } catch let error as LocalizedError {
            self.alertMessage = error.errorDescription ?? "No se pudo añadir la nueva persona."
            self.showingErrorAlert = true
        } catch {
            self.alertMessage = "Ocurrió un error inesperado al añadir la nueva persona."
            self.showingErrorAlert = true
        }
        
        isAddingNew = false
    }
}

// MARK: - Preview
#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
    
    let p1 = Person(name: "Juan Existente")
    let p2 = Person(name: "Ana Miembro")
    let p3 = Person(name: "Carlos López")
    let groupConMiembros = Group(name: "Grupo con Miembros")
    groupConMiembros.members = [p2, p3]
    
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)
    container.mainContext.insert(groupConMiembros)
    
    let vm = GroupDetailViewModel()

    return AddMemberView(group: groupConMiembros, viewModel: vm)
        .modelContainer(container)
}

