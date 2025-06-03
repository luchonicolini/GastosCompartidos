//
//  AddExpenseView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {

    var onSave: (() -> Void)?
    let group: Group
    var expenseToEdit: Expense?

    @State var viewModel = AddExpenseViewModel()
    @State private var isSaving = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) var dismiss
    @Environment(\.accessibilityReduceMotion) var reduceMotion

    @State private var showingAlert = false
    @State private var alertMessage = ""

    @FocusState var descriptionFieldIsFocused: Bool
    @FocusState var amountFieldIsFocused: Bool
    var isEditing: Bool { expenseToEdit != nil }

    let numberFormatter: NumberFormatter = {
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
                    expenseDetailsSection
                    payerSection
                    participantsSection
                    splitConfigurationSection
                }
                .padding(.vertical)
            }
            .background(
                Color("AppBackground")
                    .ignoresSafeArea()
                    .onTapGesture {
                        //UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        hideKeyboard()
                    }
            )
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(isEditing ? "Editar Gasto" : "Añadir Gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(isEditing ? "Cerrar" : "Cancelar") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                            .frame(width: 30, height: 30)
                    } else {
                        Button("Guardar") {
                            triggerSaveProcess()
                        }
                        .fontWeight(.bold)
                    }
                }
            }
            .task { viewModel.setup(expense: expenseToEdit, members: group.members ?? []) }
            .customAlert( isPresented: $showingAlert, title: "Error al Guardar", message: LocalizedStringKey(alertMessage) )
        }
    }
    
    @MainActor
    func triggerSaveProcess() { // Cambiado a internal
        descriptionFieldIsFocused = false
        amountFieldIsFocused = false
        isSaving = true
        Task {
            do {
                try viewModel.saveExpense(for: group, context: modelContext)
                onSave?()
                isSaving = false
                dismiss()
            } catch let error as ExpenseError {
                isSaving = false
                alertMessage = error.localizedDescription
                showingAlert = true
            } catch {
                isSaving = false
                alertMessage = "Ocurrió un error inesperado. \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
}



#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    guard let container = try? ModelContainer(for: Group.self, Person.self, Expense.self, configurations: config) else {
        fatalError("Failed to create ModelContainer for preview.")
    }
    
    let p1 = Person(name: "Frodo Bolsón")
    let p2 = Person(name: "Sam Gamyi")
    let p3 = Person(name: "Pippin Took")
    
    let group = Group(name: "Comunidad del Anillo", colorHex: Color.green.toHex())
    
    // Añadir miembros al contexto y al grupo
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)
    
    group.members = [p1, p2, p3]
    container.mainContext.insert(group) // Insertar el grupo después de asignar miembros si la relación se maneja así
    

    return AddExpenseView(group: group)
        .modelContainer(container)
}
