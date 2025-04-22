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
    // El grupo al que pertenece el gasto
    let group: Group
    // El gasto a editar (opcional, nil si estamos añadiendo)
    var expenseToEdit: Expense?

    // ViewModel para manejar la lógica y el estado del formulario
    @State private var viewModel = AddExpenseViewModel()

    // Contexto y dismiss del entorno
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss

    // Estado para la alerta de error
    @State private var showingAlert = false
    @State private var alertMessage = ""

    // Determinar si estamos en modo edición
    private var isEditing: Bool { expenseToEdit != nil }

    // Formateador de números para los campos de división no equitativa
     private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0 // Permite no escribir decimales si no se quiere
        formatter.locale = Locale.current // Usa el separador decimal local
        return formatter
    }()

    var body: some View {
        NavigationView {
            Form {
                // Sección 1: Detalles Básicos del Gasto
                Section("Detalles del Gasto") {
                    TextField("Descripción", text: $viewModel.description)
                    TextField("Monto Total", text: $viewModel.amountString)
                        .keyboardType(.decimalPad) // Teclado numérico para el monto
                    DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                }

                // Sección 2: Pagador
                Section("¿Quién Pagó?") {
                    Picker("Pagador", selection: $viewModel.selectedPayerId) {
                        Text("Nadie seleccionado").tag(Optional<UUID>(nil)) // Opción nula
                        ForEach(viewModel.availableMembers()) { member in
                            Text(member.name).tag(Optional(member.id))
                        }
                    }
                    // Estilo rueda puede ser mejor si hay muchos miembros
                    // .pickerStyle(.wheel)
                }

                // Sección 3: Participantes
                Section("¿Quiénes Participaron?") {
                    // Un MultiSelector sería ideal aquí. Usaremos una lista simple por ahora.
                    List(viewModel.availableMembers()) { member in
                         HStack {
                              Text(member.name)
                              Spacer()
                              if viewModel.selectedParticipantIds.contains(member.id) {
                                  Image(systemName: "checkmark.circle.fill")
                                       .foregroundStyle(.blue)
                              } else {
                                   Image(systemName: "circle")
                                       .foregroundStyle(.gray)
                              }
                         }
                         .contentShape(Rectangle()) // Hace toda la fila tappable
                         .onTapGesture {
                              toggleParticipantSelection(member.id)
                         }
                    }
                    // Botones para seleccionar/deseleccionar todos
                    HStack {
                         Button("Seleccionar Todos") {
                             viewModel.selectedParticipantIds = Set(viewModel.availableMembers().map { $0.id })
                         }
                         .buttonStyle(.borderless)
                         Spacer()
                         Button("Deseleccionar Todos") {
                             viewModel.selectedParticipantIds = []
                             // También limpiar inputs de división si se deselecciona todo
                              if viewModel.selectedSplitType != .equally {
                                   viewModel.splitInputValues = [:]
                              }
                         }
                         .buttonStyle(.borderless)
                         .foregroundStyle(.red)
                    }
                }

                // Sección 4: Tipo de División
                Section("¿Cómo Dividir el Gasto?") {
                    Picker("Método de División", selection: $viewModel.selectedSplitType) {
                        ForEach(SplitType.allCases) { type in
                            Text(type.localizedDescription).tag(type)
                        }
                    }
                    // .pickerStyle(.segmented) // Estilo segmentado si prefieres
                }

                // Sección 5: Detalles de División (Condicional)
                // Solo se muestra si el tipo de división NO es "Igual" y hay participantes seleccionados
                 if viewModel.selectedSplitType != .equally && !viewModel.selectedParticipantIds.isEmpty {
                      Section(header: Text("Detalles de División (\(viewModel.selectedSplitType.localizedDescription))")) {

                           // Filtrar miembros disponibles para mostrar solo los participantes seleccionados
                           let selectedParticipants = viewModel.availableMembers().filter {
                                viewModel.selectedParticipantIds.contains($0.id)
                           }

                           ForEach(selectedParticipants) { participant in
                               HStack {
                                    Text(participant.name)
                                    Spacer()
                                    // TextField para el input específico (monto, %, partes)
                                    TextField(splitInputPlaceholder(), text: splitInputBinding(for: participant.id))
                                         .keyboardType(.decimalPad)
                                         .multilineTextAlignment(.trailing)
                                         //.frame(width: 100) // Ajusta el ancho si es necesario
                               }
                           }
                           // Mostrar la suma actual de los inputs para ayudar al usuario
                            if let sumInfo = splitInputSumInfo() {
                                 Text(sumInfo)
                                     .font(.caption)
                                     .foregroundStyle(.secondary)
                            }
                      }
                 }

            } // Fin Form
            .navigationTitle(isEditing ? "Editar Gasto" : "Añadir Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveExpense()
                    }
                    // Podrías añadir una validación más estricta en .disabled si quieres
                    // .disabled(viewModel.description.isEmpty || viewModel.amountString.isEmpty ...)
                }
            }
            .task {
                 // Configurar el ViewModel cuando la vista aparece
                 // Pasamos el grupo, miembros y el gasto a editar (si existe)
                 viewModel.setup(expense: expenseToEdit, members: group.members ?? [])
            }
            .alert("Error al Guardar", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        } // Fin NavigationView
    } // Fin body

    // --- Funciones Auxiliares ---

    // Helper para manejar la selección/deselección de participantes
    private func toggleParticipantSelection(_ memberId: UUID) {
        if viewModel.selectedParticipantIds.contains(memberId) {
            viewModel.selectedParticipantIds.remove(memberId)
             // Limpiar input de división si se deselecciona un participante y el tipo no es igual
              if viewModel.selectedSplitType != .equally {
                   viewModel.splitInputValues.removeValue(forKey: memberId)
              }
        } else {
            viewModel.selectedParticipantIds.insert(memberId)
             // Opcional: Pre-rellenar con "0" o vacío cuando se selecciona
              if viewModel.selectedSplitType != .equally {
                   // No añadir nada aquí, dejar que el usuario ingrese
              }
        }
    }

    // Helper para obtener el placeholder correcto para los inputs de división
    private func splitInputPlaceholder() -> String {
        switch viewModel.selectedSplitType {
        case .byAmount: return "Monto"
        case .byPercentage: return "%"
        case .byShares: return "Partes"
        case .equally: return "" // No debería mostrarse
        }
    }

    // Helper para crear un Binding<String> para cada entrada del diccionario splitInputValues
    private func splitInputBinding(for participantId: UUID) -> Binding<String> {
        Binding<String>(
            get: { viewModel.splitInputValues[participantId] ?? "" },
            set: { newValue in
                 // Validar que solo se ingresen números y el separador decimal correcto
                 let filtered = newValue.filter { "0123456789.,".contains($0) }
                 // Reemplazar comas por puntos si es necesario para el formateador
                 let standardized = filtered.replacingOccurrences(of: ",", with: ".")
                 // Evitar múltiples puntos decimales
                 let components = standardized.components(separatedBy: ".")
                 if components.count <= 2 {
                      viewModel.splitInputValues[participantId] = standardized
                 } else {
                      // Si ya hay un punto y se intenta añadir otro, mantener el valor anterior
                      // (o eliminar el último carácter si se quiere)
                      if let existingValue = viewModel.splitInputValues[participantId] {
                           viewModel.splitInputValues[participantId] = String(existingValue)
                      }
                 }
            }
        )
    }

    // Helper para mostrar la suma de los inputs de división no equitativa
     private func splitInputSumInfo() -> String? {
         guard viewModel.selectedSplitType != .equally else { return nil }

         let relevantValues = viewModel.selectedParticipantIds.compactMap { id in
             viewModel.splitInputValues[id]
         }
         guard !relevantValues.isEmpty else { return "Total: 0" } // Si no hay inputs, suma es 0

         var sum: Double = 0
         for stringValue in relevantValues {
              // Usar el formateador para interpretar el string del usuario
              if let number = numberFormatter.number(from: stringValue) {
                   sum += number.doubleValue
              } else if !stringValue.isEmpty {
                    // Si no se puede parsear y no está vacío, indica un problema
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


    // Función para guardar el gasto
    @MainActor
    private func saveExpense() {
        do {
            // Llama a la función del ViewModel para guardar/actualizar
            try viewModel.saveExpense(for: group, context: modelContext)
            // Si tiene éxito, cierra la vista
            dismiss()
        } catch let error as ExpenseError {
             // Captura errores específicos lanzados por el ViewModel
             alertMessage = error.localizedDescription
             showingAlert = true
        } catch {
            // Otros errores inesperados
            print("Error inesperado al guardar gasto: \(error)")
            alertMessage = "Ocurrió un error inesperado. \(error.localizedDescription)"
            showingAlert = true
        }
    }
}

// --- Vista Previa (Preview) ---
#Preview {
    // 1. Configura el contenedor
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config)

    // 2. Crea datos de ejemplo
    let p1 = Person(name: "Frodo")
    let p2 = Person(name: "Sam")
    let p3 = Person(name: "Pippin")
    let group = Group(name: "Comunidad")
    group.members = [p1, p2, p3]

    // Opcional: un gasto para probar el modo edición
    let expenseToEdit = Expense(description: "Lembas", amount: 25.5, payer: p1, participants: [p1, p2], group: group, splitType: .equally)

    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)
    container.mainContext.insert(group)
    // container.mainContext.insert(expenseToEdit) // Descomenta para probar edición

    // 3. Retorna la vista
    return AddExpenseView(group: group) // Para añadir nuevo
    // return AddExpenseView(group: group, expenseToEdit: expenseToEdit) // Para editar
           .modelContainer(container)
}
