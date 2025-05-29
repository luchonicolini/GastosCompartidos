//
//  AddExpenseView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

// Views/AddExpenseView.swift
import SwiftUI
import SwiftData

struct AddExpenseView: View {

    var onSave: (() -> Void)?
    let group: Group
    var expenseToEdit: Expense?

    @State private var viewModel = AddExpenseViewModel()
    @State private var isSaving = false // <-- PASO 1: Nuevo estado

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var showingAlert = false
    @State private var alertMessage = ""

    @FocusState private var descriptionFieldIsFocused: Bool
    @FocusState private var amountFieldIsFocused: Bool

    private var isEditing: Bool { expenseToEdit != nil }

    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        formatter.locale = Locale.current
        return formatter
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 0) {
                        TextField("Descripción (Ej: Cena, Supermercado)", text: $viewModel.description)
                            .focused($descriptionFieldIsFocused)
                            .padding(.vertical, 10)
                        Divider()
                        HStack(spacing: 0) {
                            Text(Locale.current.currencySymbol ?? "$")
                                .foregroundStyle(.gray)
                                .padding(.trailing, 4)
                            TextField("0.00", text: $viewModel.amountString)
                                .keyboardType(.decimalPad)
                                .focused($amountFieldIsFocused)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(.vertical, 10)
                        Divider()
                        DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                            .padding(.vertical, 6)
                    }
                    .padding(.horizontal)
                    //.background(Color("ColorButton").opacity(0.7), in: RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Quién Pagó?")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal)
                        Picker("Pagador", selection: $viewModel.selectedPayerId) {
                            Text("Nadie seleccionado").tag(nil as UUID?)
                                .font(.body)
                                .fontDesign(.rounded)
                            ForEach(viewModel.availableMembers()) { member in
                                Text(member.name).tag(member.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: 10))
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("¿Quiénes Participaron?")
                            .font(.headline)
                            .foregroundStyle(Color.primary)
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 15) {
                                ForEach(viewModel.availableMembers()) { member in
                                    ParticipantAvatar(
                                        member: member,
                                        isSelected: viewModel.selectedParticipantIds.contains(member.id),
                                        accentColor: group.displayColor
                                    )
                                    .onTapGesture {
                                        withAnimation(reduceMotion ? nil : .spring(response: 0.3)) {
                                             toggleParticipantSelection(member.id)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 5)
                        }
                        HStack {
                             Button("Todos") {
                                 viewModel.selectedParticipantIds = Set(viewModel.availableMembers().map { $0.id })
                             }
                                .buttonStyle(.bordered)
                                .tint(group.displayColor)
                             Button("Ninguno") {
                                 viewModel.selectedParticipantIds = []
                                  if viewModel.selectedSplitType != .equally {
                                       viewModel.splitInputValues = [:]
                                  }
                             }
                                .buttonStyle(.bordered)
                                .tint(.gray)
                             Spacer()
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("¿Cómo Dividir?")
                            .font(.headline)
                            .foregroundStyle(Color.primary)

                        Picker("Método", selection: $viewModel.selectedSplitType.animation()) {
                            ForEach(SplitType.allCases) { type in
                                Text(type.localizedDescription).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray5),
                                    in: RoundedRectangle(cornerRadius: 10))

                        if viewModel.selectedSplitType != .equally && !viewModel.selectedParticipantIds.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                               Text("Detalles de División: \(viewModel.selectedSplitType.localizedDescription)")
                                   .font(.subheadline).bold()
                                   .foregroundStyle(Color.secondary)
                               let selectedParticipants = viewModel.availableMembers()
                                   .filter { viewModel.selectedParticipantIds.contains($0.id) }
                                   .sorted { $0.name < $1.name }
                               ForEach(selectedParticipants) { participant in
                                   HStack {
                                       Text(participant.name)
                                            .foregroundStyle(Color.primary)
                                        Spacer()
                                        TextField(splitInputPlaceholder(), text: splitInputBinding(for: participant.id))
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .padding(8)
                                            .background(Color(.systemGray4).opacity(0.8),
                                                        in: RoundedRectangle(cornerRadius: 8))
                                            .foregroundStyle(Color.primary)
                                            .frame(width: 100)
                                   }
                               }
                               if let sumInfo = splitInputSumInfo() {
                                  Text(sumInfo)
                                        .font(.caption)
                                        .foregroundStyle(Color.secondary)
                                        .padding(.top, 5)
                               }
                            }
                            .padding()
                            .background(Color(.systemGray6),
                                        in: RoundedRectangle(cornerRadius: 10))
                            .padding(.top, 5)
                            .transition(.asymmetric(insertion: .scale(scale: 0.9, anchor: .top).combined(with: .opacity),
                                                    removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .top))))
                        }
                    }
                    .padding(.horizontal)
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(
                Color("AppBackground")
                    .ignoresSafeArea()
                    .onTapGesture {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//                        descriptionFieldIsFocused = false
//                        amountFieldIsFocused = false
                    }
            )
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Editar Gasto" : "Añadir Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                        .disabled(isSaving) // Deshabilitar Cancelar mientras se guarda
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // <-- PASO 2: Modificar el botón de Guardar
                    if isSaving {
                        ProgressView()
                            .frame(width: 30, height: 30) // Darle un tamaño para que sea visible
                    } else {
                        Button("Guardar") {
                            triggerSaveProcess() // Llamar a la nueva función
                        }
                        .fontWeight(.bold)
                   
                    }
                }
            }
            .task { viewModel.setup(expense: expenseToEdit, members: group.members ?? []) }
            .customAlert( isPresented: $showingAlert, title: "Error al Guardar", message: LocalizedStringKey(alertMessage) )
            .scrollDismissesKeyboard(.interactively)
        }
    }
    
    private func toggleParticipantSelection(_ memberId: UUID) {
        if viewModel.selectedParticipantIds.contains(memberId) {
            viewModel.selectedParticipantIds.remove(memberId)
            if viewModel.selectedSplitType != .equally {
                viewModel.splitInputValues.removeValue(forKey: memberId)
            }
        } else {
            viewModel.selectedParticipantIds.insert(memberId)
        }
    }
    
    private func splitInputPlaceholder() -> String {
        switch viewModel.selectedSplitType {
        case .byAmount: return "Monto"
        case .byPercentage: return "%"
        case .byShares: return "Partes"
        case .equally: return ""
        }
    }
    
    private func splitInputBinding(for participantId: UUID) -> Binding<String> {
        Binding<String>(
            get: { viewModel.splitInputValues[participantId] ?? "" },
            set: { newValue in
                let filtered = newValue.filter { "0123456789.,".contains($0) }
                let standardized = filtered.replacingOccurrences(of: ",", with: ".")
                let components = standardized.components(separatedBy: ".")
                if components.count <= 2 {
                    viewModel.splitInputValues[participantId] = standardized
                } else {
                    if let existingValue = viewModel.splitInputValues[participantId] {
                        viewModel.splitInputValues[participantId] = String(existingValue)
                    }
                }
            }
        )
    }
    
    private func splitInputSumInfo() -> String? {
        guard viewModel.selectedSplitType != .equally else { return nil }
        let relevantValues = viewModel.selectedParticipantIds.compactMap { id in
            viewModel.splitInputValues[id]
        }
        guard !relevantValues.isEmpty else { return "Total: 0" }
        var sum: Double = 0
        for stringValue in relevantValues {
            if let number = numberFormatter.number(from: stringValue) {
                sum += number.doubleValue
            } else if !stringValue.isEmpty {
                return "Valor inválido detectado"
            }
        }
        let formattedSum = String(format: "%.2f", sum)
        switch viewModel.selectedSplitType {
        case .byAmount: return "Suma: \(formattedSum)"
        case .byPercentage: return "Suma: \(formattedSum)%"
        case .byShares: return "Total Partes: \(formattedSum)"
        case .equally: return nil
        }
    }
    
    // <-- PASO 3: Ajustar la función de guardado
    @MainActor
    private func triggerSaveProcess() {
        // Ocultar teclado antes de intentar guardar
        descriptionFieldIsFocused = false
        amountFieldIsFocused = false
        
        isSaving = true
        
        // Usamos un Task para asegurar que la UI se actualice (isSaving = true)
        // y para manejar el final de la operación de guardado de forma limpia.
        Task {
            do {
                // Intenta guardar el gasto a través del ViewModel
                try viewModel.saveExpense(for: group, context: modelContext)
                
                // Si tiene éxito:
                onSave?() // Llama al callback onSave si existe
                isSaving = false // Restablece el estado
                dismiss()    // Cierra la vista
                
            } catch let error as ExpenseError {
                // Si hay un error conocido de la app:
                isSaving = false // Restablece el estado
                alertMessage = error.localizedDescription
                showingAlert = true
                
            } catch {
                // Si hay un error inesperado:
                isSaving = false // Restablece el estado
                alertMessage = "Ocurrió un error inesperado. \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}

// --- Vista Previa (Preview) ---
// (El código del Preview no necesita cambios)
#Preview {
    // ... (código del preview existente) ...
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)
    let p1 = Person(name: "Frodo")
    let p2 = Person(name: "Sam")
    let p3 = Person(name: "Pippin")
    let group = Group(name: "Comunidad")
    group.members = [p1, p2, p3]
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)
    container.mainContext.insert(group)
    return AddExpenseView(group: group)
        .modelContainer(container)
}


struct ParticipantAvatar: View {
    // Datos que necesita la vista para mostrarse
    let member: Person  // La persona a representar
    let isSelected: Bool // Si está seleccionada o no
    let accentColor: Color // El color de acento (probablemente group.displayColor)

    var body: some View {
        VStack(spacing: 4) {
            Text(member.name.prefix(1)) // Muestra la primera letra del nombre
                .font(isSelected ? .title2 : .title3) // Fuente un poco más grande si está seleccionado
                .fontWeight(.medium)
                 // Cambia el tamaño del frame si está seleccionado
                .frame(width: isSelected ? 50 : 45, height: isSelected ? 50 : 45)
                // Fondo: usa el color de acento con opacidad si está seleccionado, o un gris si no
                .background(isSelected ? accentColor.opacity(0.3) : Color(.systemGray5))
                // Color de la letra: usa el color de acento si está seleccionado, o el primario si no
                .foregroundStyle(isSelected ? accentColor : Color(.primaryText)) // <- Usa tu color adaptativo
                .clipShape(Circle()) // Forma circular
                // Añade un borde de color de acento si está seleccionado
                .overlay(
                    Circle()
                        .stroke(isSelected ? accentColor : Color.gray, lineWidth: 2.5)
                    
                )

            // Nombre debajo del círculo
            Text(member.name)
                .font(.caption) // Fuente pequeña para el nombre
                .lineLimit(1) // Evita que el nombre ocupe múltiples líneas
                 
                .foregroundStyle(isSelected ? accentColor : Color(.primaryText)) // <- Usa tu color adaptativo
        }
        .opacity(isSelected ? 1.0 : 0.75)
        
        .animation(.spring(), value: isSelected)
    }
}
