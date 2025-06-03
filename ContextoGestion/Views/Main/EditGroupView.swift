//
//  EditGroupView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 01/06/2025.
//


//
//  EditGroupView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 01/06/2025.
//

import SwiftUI
import SwiftData

struct EditGroupView: View {
    let group: Group
    
    // SOLUCIÓN 1: Inicializar los estados directamente en la declaración
    @State private var groupName: String
    @State private var selectedColor: Color
    @State private var selectedIconName: String
    
    @State private var showColorError: Bool = false
    @State private var isFormValid: Bool = false
    @State private var showPreview: Bool = false
    @FocusState private var nameFieldFocused: Bool
    
    // SOLUCIÓN 2: Agregar un estado para controlar si ya se inicializó
    @State private var hasInitialized: Bool = false
    
    // Iconos organizados por categorías (mismo que AddGroupView)
    let iconCategories: [(String, [String])] = [
        ("Personas", ["person.3.sequence.fill", "figure.2.and.child.holdinghands", "person.2.circle.fill", "person.crop.circle.fill"]),
        ("Lugares", ["house.fill", "building.2.fill", "location.fill", "mappin.and.ellipse"]),
        ("Transporte", ["car.fill", "airplane", "bus.fill", "tram.fill", "bicycle", "fuelpump.fill"]),
        ("Comida", ["fork.knife", "cup.and.saucer.fill", "takeoutbag.and.cup.and.straw.fill", "birthday.cake.fill"]),
        ("Compras", ["cart.fill", "bag.fill", "creditcard.fill", "giftcard.fill"]),
        ("Dinero", ["dollarsign.circle.fill", "eurosign.circle.fill", "banknote.fill", "creditcard.trianglebadge.exclamationmark"]),
        ("Entretenimiento", ["gamecontroller.fill", "tv.fill", "music.note", "camera.fill"]),
        ("Otros", ["heart.fill", "paintbrush.fill", "hammer.fill", "wrench.and.screwdriver.fill", "pawprint.fill", "gift.fill"])
    ]
    
    // Paleta de colores moderna con nombres (mismo que AddGroupView)
    let colorPalette: [(Color, String)] = [
        (.red, "Rojo"), (.orange, "Naranja"), (.yellow, "Amarillo"),
        (.green, "Verde"), (.mint, "Menta"), (.teal, "Verde Azulado"),
        (.cyan, "Cian"), (.blue, "Azul"), (.indigo, "Índigo"),
        (.purple, "Púrpura"), (.pink, "Rosa"), (Color(.systemGray4), "Gris")
    ]
    
    var onSave: (String, String, String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // SOLUCIÓN 1: Custom initializer para inicializar los estados correctamente
    init(group: Group, onSave: @escaping (String, String, String) -> Void) {
        self.group = group
        self.onSave = onSave
        
        // Inicializar los estados directamente aquí
        self._groupName = State(initialValue: group.name)
        self._selectedIconName = State(initialValue: group.iconName ?? "person.3.sequence.fill")
        self._selectedColor = State(initialValue: group.displayColor)
        self._isFormValid = State(initialValue: !group.name.isEmpty)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header con preview
                    VStack(spacing: 20) {
                        Text("Editar grupo")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        // Preview Card
                        GroupPreviewCard(
                            iconName: selectedIconName,
                            color: selectedColor,
                            groupName: groupName.isEmpty ? "Nombre del grupo" : groupName,
                            isPlaceholder: groupName.isEmpty
                        )
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                showPreview.toggle()
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    // Formulario
                    VStack(spacing: 24) {
                        // Campo de nombre
                        GroupNameField(
                            text: $groupName,
                            isValid: $isFormValid,
                            isFocused: $nameFieldFocused,
                            selectedColor: selectedColor
                        )
                        
                        // Selector de Color
                        ColorSelectionSection(
                            selectedColor: $selectedColor,
                            colorPalette: colorPalette,
                            reduceMotion: reduceMotion
                        )
                        
                        // Selector de Iconos por Categorías
                        IconCategoriesSection(
                            selectedIconName: $selectedIconName,
                            selectedColor: selectedColor,
                            iconCategories: iconCategories,
                            reduceMotion: reduceMotion
                        )
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .onChange(of: groupName) { _, newValue in
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isFormValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
                }
            }
            .background(Color("AppBackground").ignoresSafeArea())
            .navigationTitle("Editar Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveGroup()
                    }
                    .font(.headline)
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? selectedColor : .secondary)
                }
            }
            .alert("Error de Color", isPresented: $showColorError) {
                Button("Entendido", role: .cancel) { }
            } message: {
                Text("Hubo un problema al procesar el color seleccionado. Intenta con otro color.")
            }
            .onTapGesture {
                nameFieldFocused = false
            }
            // SOLUCIÓN 3: Agregar un task para verificar la inicialización
            .task {
                if !hasInitialized {
                    await setupInitialValuesAsync()
                }
            }
            // SOLUCIÓN 4: Mantener onAppear como respaldo pero con verificación
            .onAppear {
                if !hasInitialized {
                    setupInitialValuesSync()
                }
            }
        }
    }
    
    // SOLUCIÓN 3: Método async para inicialización
    @MainActor
    private func setupInitialValuesAsync() async {
        guard !hasInitialized else { return }
        
        // Pequeño delay para asegurar que la vista esté lista
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 segundos
        
        withAnimation(.easeInOut(duration: 0.3)) {
            groupName = group.name
            selectedIconName = group.iconName ?? "person.3.sequence.fill"
            selectedColor = group.displayColor
            isFormValid = !group.name.isEmpty
            hasInitialized = true
        }
    }
    
    // SOLUCIÓN 4: Método síncrono como respaldo
    private func setupInitialValuesSync() {
        guard !hasInitialized else { return }
        
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.groupName = self.group.name
                self.selectedIconName = self.group.iconName ?? "person.3.sequence.fill"
                self.selectedColor = self.group.displayColor
                self.isFormValid = !self.group.name.isEmpty
                self.hasInitialized = true
            }
        }
    }
    
    private func saveGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let colorHex = selectedColor.toHex()
        if let validColorHex = colorHex {
            // Feedback háptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onSave(trimmedName, selectedIconName, validColorHex)
            dismiss()
        } else {
            showColorError = true
        }
    }
}

#Preview("Edit Group View") {
    do {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Group.self, Person.self, configurations: config)
        
        let sampleGroup = Group(
            name: "Grupo de Ejemplo",
            creationDate: Date(),
            iconName: "house.fill",
            colorHex: "#34A853"
        )
        
        container.mainContext.insert(sampleGroup)
        
        return EditGroupView(group: sampleGroup) { name, icon, colorHex in
            print("Saving group: \(name), Icon: \(icon), Color: \(colorHex)")
        }
        .modelContainer(container)
        
    } catch {
        return Text("Error creating preview: \(error)")
    }
}
