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

    let suggestedIcons = [
        "person.3.sequence.fill", "figure.2.and.child.holdinghands", "house.fill",
        "car.fill", "airplane", "bus.fill", "tram.fill", "bicycle",
        "fuelpump.fill", "fork.knife", "cup.and.saucer.fill", "cart.fill",
        "bag.fill", "creditcard.fill", "dollarsign.circle.fill", "eurosign.circle.fill",
        "heart.fill", "gamecontroller.fill", "paintbrush.fill", "hammer.fill",
        "wrench.and.screwdriver.fill", "building.2.fill", "pawprint.fill", "gift.fill"
    ]
    var onAdd: (String, String, String) -> Void
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    private let iconGridColumns: [GridItem] = Array(repeating: .init(.flexible()), count: 5)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                     VStack {
                         Text("Icono y Color del Grupo:")
                             .font(.headline)
                             .accessibilityAddTraits(.isHeader)
                         Image(systemName: selectedIconName)
                             .font(.system(size: 50))
                             .foregroundStyle(selectedColor)
                             .frame(width: 100, height: 100)
                             .background(selectedColor.opacity(0.15))
                             .clipShape(RoundedRectangle(cornerRadius: 15))
                             .padding(.bottom, 5)
                             .animation(reduceMotion ? nil : .smooth, value: selectedIconName)
                             .animation(reduceMotion ? nil : .smooth, value: selectedColor)
                             .accessibilityLabel("Icono seleccionado: \(selectedIconName)")
                     }
                     .padding(.top)

                     // --- Campo de Nombre ---
                     HStack(spacing: 10) {
                         Image(systemName: selectedIconName)
                             .font(.title2)
                             .foregroundStyle(selectedColor)
                             .frame(width: 20, height: 20)
                             .accessibilityHidden(true)

                         TextField("Nombre del Grupo", text: $groupName)
                             .textFieldStyle(.roundedBorder)
                             .accessibilityLabel("Nombre del grupo")

                     }
                     .padding(.horizontal)

                     // --- Selector de Color ---
                     ColorPicker("Seleccionar Color", selection: $selectedColor, supportsOpacity: false)
                         .padding(.horizontal)
                         .accessibilityHint("Doble tap para abrir el selector de color")

                     // --- Selector de Icono ---
                     VStack(alignment: .leading) {
                         Text("Seleccionar Icono")
                             .font(.subheadline)
                             .padding(.horizontal)
                             .accessibilityAddTraits(.isHeader)

                         LazyVGrid(columns: iconGridColumns, spacing: 15) {
                             ForEach(suggestedIcons, id: \.self) { iconName in
                                 Button(action: {
                                     withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                                         selectedIconName = iconName
                                     }
                                 }) {
                                     Image(systemName: iconName)
                                         .font(.title2)
                                         .frame(minWidth: 0, maxWidth: .infinity, minHeight: 50)
                                         .background(selectedIconName == iconName ? selectedColor.opacity(0.25) : Color(.systemGray6))
                                         .clipShape(RoundedRectangle(cornerRadius: 10))
                                         .foregroundStyle(selectedIconName == iconName ? selectedColor : .primary)
                                 }
                                 .accessibilityLabel("Icono \(iconName)")
                                 .accessibilityAddTraits(selectedIconName == iconName ? [.isSelected] : [])
                             }
                         }
                         .padding(.horizontal)
                     } // Fin VStack Icon Selector

                     Spacer()

                } // Fin VStack Principal
                .padding(.vertical)

            } // Fin ScrollView
            .background(.thinMaterial)
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
        } // Fin NavigationStack
    }
}

#Preview {
    AddGroupView { name, icon, colorHex in
        print("Adding group: \(name), Icon: \(icon), Color: \(colorHex)")
    }
}
