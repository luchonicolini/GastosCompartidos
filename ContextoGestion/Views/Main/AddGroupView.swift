//
//  AddGroupView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//


import SwiftUI
import SwiftData

struct AddGroupView: View {
    @State private var groupName: String = ""
    @State private var selectedColor: Color = .blue
    @State private var selectedIconName: String = "person.3.sequence.fill"
    @State private var showColorError: Bool = false
    @State private var isFormValid: Bool = false
    @State private var showPreview: Bool = false
    @FocusState private var nameFieldFocused: Bool
    
    // Iconos organizados por categorías
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
    
    // Paleta de colores moderna con nombres
    let colorPalette: [(Color, String)] = [
        (.red, "Rojo"), (.orange, "Naranja"), (.yellow, "Amarillo"),
        (.green, "Verde"), (.mint, "Menta"), (.teal, "Verde Azulado"),
        (.cyan, "Cian"), (.blue, "Azul"), (.indigo, "Índigo"),
        (.purple, "Púrpura"), (.pink, "Rosa"), (Color(.systemGray4), "Gris")
    ]
    
    var onAdd: (String, String, String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header con preview mejorado
                    VStack(spacing: 20) {
                        Text("Crea tu nuevo grupo")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        
                        // Preview Card Mejorado
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
                        // Campo de nombre mejorado
                        GroupNameField(
                            text: $groupName,
                            isValid: $isFormValid,
                            isFocused: $nameFieldFocused,
                            selectedColor: selectedColor
                        )
                        
                        // Selector de Color Mejorado
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
                    
                    Spacer(minLength: 100) // Espacio para evitar que se tape con el teclado
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
            .navigationTitle("Nuevo Grupo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Crear") {
                        createGroup()
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
        }
    }
    
    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        let colorHex = selectedColor.toHex()
        if let validColorHex = colorHex {
            // Feedback háptico
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            onAdd(trimmedName, selectedIconName, validColorHex)
            dismiss()
        } else {
            showColorError = true
        }
    }
}

// MARK: - Componentes Auxiliares

struct GroupPreviewCard: View {
    let iconName: String
    let color: Color
    let groupName: String
    let isPlaceholder: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icono
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(groupName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(isPlaceholder ? .secondary : .primary)
                    .animation(.easeInOut(duration: 0.2), value: groupName)
                
                Text("0 miembros • $0.00")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
}

struct GroupNameField: View {
    @Binding var text: String
    @Binding var isValid: Bool
    @FocusState.Binding var isFocused: Bool
    let selectedColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Nombre del grupo")
                    .font(.headline)
                Spacer()
                if !text.isEmpty {
                    Text("\(text.count)/30")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            TextField("Ej. Viaje a Barcelona, Gastos Casa...", text: $text)
                .textFieldStyle(ModernTextFieldStyle(
                    isValid: isValid,
                    isFocused: isFocused,
                    color: selectedColor
                ))
                .focused($isFocused)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(false)
                .submitLabel(.done)
                .onSubmit {
                    isFocused = false
                }
                .onChange(of: text) { _, newValue in
                    if newValue.count > 30 {
                        text = String(newValue.prefix(30))
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        isFocused = true
                    }
                }
        }
    }
}

struct ModernTextFieldStyle: TextFieldStyle {
    let isValid: Bool
    let isFocused: Bool
    let color: Color
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isFocused ? color : (isValid ? Color.clear : Color(.systemGray4)),
                        lineWidth: isFocused ? 2 : 1
                    )
            )
            .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

struct ColorSelectionSection: View {
    @Binding var selectedColor: Color
    let colorPalette: [(Color, String)]
    let reduceMotion: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Color del grupo")
                .font(.headline)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                ForEach(Array(colorPalette.enumerated()), id: \.offset) { index, colorInfo in
                    let (color, name) = colorInfo
                    
                    Button(action: {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        
                        withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedColor = color
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(color)
                                .frame(width: 44, height: 44)
                            
                            if selectedColor == color {
                                Circle()
                                    .stroke(Color.primary, lineWidth: 3)
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .accessibilityLabel(name)
                    .accessibilityAddTraits(selectedColor == color ? [.isSelected] : [])
                }
            }
        }
    }
}

struct IconCategoriesSection: View {
    @Binding var selectedIconName: String
    let selectedColor: Color
    let iconCategories: [(String, [String])]
    let reduceMotion: Bool
    @State private var expandedCategories: Set<String> = ["Personas"] // Primera categoría expandida por defecto
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Icono del grupo")
                .font(.headline)
            
            ForEach(iconCategories, id: \.0) { category, icons in
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            if expandedCategories.contains(category) {
                                expandedCategories.remove(category)
                            } else {
                                expandedCategories.insert(category)
                            }
                        }
                    }) {
                        HStack {
                            Text(category)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(expandedCategories.contains(category) ? 0 : -90))
                        }
                        .padding(.vertical, 4)
                    }
                    
                    if expandedCategories.contains(category) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                            ForEach(icons, id: \.self) { iconName in
                                Button(action: {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                    
                                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedIconName = iconName
                                    }
                                }) {
                                    Image(systemName: iconName)
                                        .font(.title2)
                                        .frame(width: 52, height: 52)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(selectedIconName == iconName ? selectedColor.opacity(0.2) : Color(.systemGray6))
                                        )
                                        .foregroundStyle(selectedIconName == iconName ? selectedColor : .primary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(selectedIconName == iconName ? selectedColor : Color.clear, lineWidth: 2)
                                        )
                                }
                                .accessibilityLabel("Icono \(iconName)")
                                .accessibilityAddTraits(selectedIconName == iconName ? [.isSelected] : [])
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95)),
                            removal: .opacity
                        ))
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 1)
                )
            }
        }
    }
}

#Preview("Add Group View Mejorada") {
    AddGroupView { name, icon, colorHex in
        print("Adding group: \(name), Icon: \(icon), Color: \(colorHex)")
    }
}

