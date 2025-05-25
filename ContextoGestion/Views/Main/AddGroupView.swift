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
    @State private var selectedColor: Color = .blue // Color por defecto
    @State private var selectedIconName: String = "person.3.sequence.fill"
    @State private var showColorError: Bool = false
    @FocusState private var nameFieldFocused: Bool
    
    let suggestedIcons = [
        "person.3.sequence.fill", "figure.2.and.child.holdinghands", "house.fill",
        "car.fill", "airplane", "bus.fill", "tram.fill", "bicycle",
        "fuelpump.fill", "fork.knife", "cup.and.saucer.fill", "cart.fill",
        "bag.fill", "creditcard.fill", "dollarsign.circle.fill", "eurosign.circle.fill",
        "heart.fill", "gamecontroller.fill", "paintbrush.fill", "hammer.fill",
        "wrench.and.screwdriver.fill", "building.2.fill", "pawprint.fill", "gift.fill"
    ]
    
    // Paleta de colores predefinidos para el nuevo selector
    let predefinedColors: [Color] = [
        .red, .orange, .yellow, .green, .mint, .teal,
        .cyan, .blue, .indigo, .purple, .pink, Color(.systemGray4) // Un gris como opción
    ]
    
    var onAdd: (String, String, String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    private let iconGridColumns: [GridItem] = Array(repeating: .init(.flexible()), count: 5)
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 24) { // Aumenté un poco el spacing general
                        VStack {
                            Text("Icono y Color del Grupo:")
                                .font(.headline)
                            Image(systemName: selectedIconName)
                                .font(.system(size: 50))
                                .foregroundStyle(selectedColor) // El icono toma el color seleccionado
                                .frame(width: 100, height: 100)
                                .background(selectedColor.opacity(0.15)) // Fondo del preview usa el color con opacidad
                                .clipShape(RoundedRectangle(cornerRadius: 15))
                                .padding(.bottom, 5)
                                .animation(reduceMotion ? nil : .smooth, value: selectedIconName)
                                .animation(reduceMotion ? nil : .smooth, value: selectedColor)
                        }
                        .padding(.top)
                        
                        TextField("Nombre del Grupo", text: $groupName)
                            .padding(.vertical, 12) // Padding interno vertical para el texto
                            .padding(.horizontal, 15) // Padding interno horizontal para el texto
                            .background(
                                // Usamos un color de fondo del sistema que se adapta bien
                                // al modo claro/oscuro y es sutil.
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                                // Alternativa: Color("TextFieldBackground") si tienes uno definido en Assets
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 10)) // Asegura que el fondo respete las esquinas
                            .overlay(
                                // Borde que cambia de color con el foco
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(nameFieldFocused ? selectedColor : Color(.systemGray3), lineWidth: 1.5)
                                // Cuando está enfocado usa el 'selectedColor', sino un gris sutil.
                                // Puedes cambiar 'selectedColor' por 'Color.accentColor' o tu color de acento principal
                                // si prefieres que el foco siempre sea del mismo color.
                            )
                            .focused($nameFieldFocused)
                            .autocorrectionDisabled(true)
                            .textInputAutocapitalization(.words)
                            .padding(.horizontal) // Padding exterior para separar el TextField de los bordes de la pantalla
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    nameFieldFocused = true
                                }
                            }
                        
                        // --- NUEVO SELECTOR DE COLOR ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seleccionar Color")
                                .font(.subheadline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(predefinedColors, id: \.self) { color in
                                        Circle()
                                            .fill(color)
                                            .frame(width: 36, height: 36)
                                            .overlay(
                                                // Añadir un borde o un checkmark si es el color seleccionado
                                                Circle()
                                                    .stroke(selectedColor == color ? Color.primary.opacity(0.7) : Color.clear, lineWidth: 2.5)
                                                    .padding(-3) // Para que el borde esté un poco hacia afuera
                                            )
                                            .onTapGesture {
                                                withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                                                    selectedColor = color
                                                }
                                            }
                                            .accessibilityLabel(color.description) // Mejorar accesibilidad si es posible
                                            .accessibilityAddTraits(selectedColor == color ? [.isSelected] : [])
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 4) // Pequeño padding vertical para el scrollview
                            }
                        }
                        // --- FIN NUEVO SELECTOR DE COLOR ---
                        
                        // --- Selector de Icono (sin cambios en su lógica interna) ---
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Seleccionar Icono")
                                .font(.subheadline)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                LazyHGrid(rows: [GridItem(.fixed(50))], spacing: 15) {
                                    ForEach(suggestedIcons, id: \.self) { iconName in
                                        Button(action: {
                                            withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                                                selectedIconName = iconName
                                            }
                                        }) {
                                            Image(systemName: iconName)
                                                .font(.title2)
                                                .frame(width: 50, height: 50)
                                                .background(selectedIconName == iconName ? selectedColor.opacity(0.25) : Color(.systemGray6))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                                .foregroundStyle(selectedIconName == iconName ? selectedColor : .primary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        Spacer()
                    }
                    .padding(.vertical)
                    .padding(.bottom, geometry.safeAreaInsets.bottom)
                }
                .background(
                    Color("AppBackground")
                        .onTapGesture {
                            nameFieldFocused = false
                        }
                )
                .navigationTitle("Nuevo Grupo")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancelar") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Añadir") {
                            let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !trimmedName.isEmpty {
                                let colorHex = selectedColor.toHex()
                                if let validColorHex = colorHex {
                                    onAdd(trimmedName, selectedIconName, validColorHex)
                                    dismiss()
                                } else {
                                    showColorError = true
                                }
                            }
                        }
                        .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .alert("Error de Color", isPresented: $showColorError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text("No se pudo convertir el color seleccionado. Por favor, elija otro color.")
                }
            }
            .background(Color("AppBackground").ignoresSafeArea())
        }
    }
}

#Preview {
    AddGroupView { name, icon, colorHex in
        print("Adding group: \(name), Icon: \(icon), Color: \(colorHex)")
    }
}

