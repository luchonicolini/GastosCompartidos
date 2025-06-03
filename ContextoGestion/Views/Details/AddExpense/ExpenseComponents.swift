//
//  ExpenseInfoSection.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 30/05/2025.
//

// ExpenseFormComponents.swift
import SwiftUI
import SwiftData

extension AddExpenseView {

    @ViewBuilder
    var expenseDetailsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            TextField("Descripción (Ej: Cena, Supermercado)", text: $viewModel.description)
                .focused($descriptionFieldIsFocused)
                .padding(.vertical, 12)
                .padding(.horizontal, 16)

            Divider().padding(.leading, 16)

            HStack(spacing: 0) {
                Text(Locale.current.currencySymbol ?? "$")
                    .foregroundStyle(.secondary)
                    .padding(.leading, 16)
                    .padding(.trailing, 4)
                TextField("0.00", text: $viewModel.amountString)
                    .keyboardType(.decimalPad)
                    .focused($amountFieldIsFocused)
                    .multilineTextAlignment(.leading)
                    .padding(.trailing, 16)
            }
            .padding(.vertical, 12)

            Divider().padding(.leading, 16)

            DatePicker("Fecha", selection: $viewModel.date, displayedComponents: .date)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
        }
//       // .background(
//            RoundedRectangle(cornerRadius: 12)
//                .fill(Color(.systemBackground))
//                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
       // )
//        .overlay(
//            RoundedRectangle(cornerRadius: 12)
//                .stroke(group.displayColor.opacity(0.2), lineWidth: 1)
//        )
        .padding(.horizontal)
    }

    @ViewBuilder
    var payerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "creditcard.fill")
                    .foregroundStyle(group.displayColor)
                
                    .font(.title3)
                Text("¿Quién Pagó?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 0) {
                Picker("Pagador", selection: $viewModel.selectedPayerId) {
                    Text("Seleccionar pagador").tag(nil as UUID?)
                        .font(.body)
                    ForEach(viewModel.availableMembers()) { member in
                        Text(member.name).tag(member.id as UUID?)
                            .font(.body)
                    }
                }
                .font(.body)
                .pickerStyle(.menu)
                .accentColor(Color("ColorButton")) 
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.colorButton.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AppBackground"))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.colorButton.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    var participantsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("¿Quiénes Participaron?")
                .font(.headline)
                .fontWeight(.semibold)
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
    }

    @ViewBuilder
    var splitConfigurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: "divide.circle.fill")
                    .foregroundStyle(group.displayColor)
                    .font(.title3)
                Text("¿Cómo Dividir?")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.primary)
                Spacer()
            }
            .padding(.horizontal)
            
            VStack(alignment: .leading, spacing: 0) {
                Picker("Método", selection: $viewModel.selectedSplitType.animation()) {
                    ForEach(SplitType.allCases) { type in
                        Text(type.localizedDescription).tag(type)
                            .font(.body)
                    }
                }
                .font(.body)
                .pickerStyle(.menu)
                .accentColor(Color("ColorButton")) 
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                
                Rectangle()
                    .fill(Color.colorButton.opacity(0.3))
                    .frame(height: 2)
                    .padding(.horizontal, 16)
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color("AppBackground"))
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.colorButton.opacity(0.2), lineWidth: 1)
            )
            .padding(.horizontal)
            
            if viewModel.selectedSplitType != .equally && !viewModel.selectedParticipantIds.isEmpty {
                splitDetailsInputsSection
            }
        }
    }

    @ViewBuilder
    var splitDetailsInputsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "list.number")
                    .foregroundStyle(group.displayColor.opacity(0.7))
                Text("Detalles de División: \(viewModel.selectedSplitType.localizedDescription)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.secondary)
                Spacer()
            }
            
            let selectedParticipants = viewModel.availableMembers()
                .filter { viewModel.selectedParticipantIds.contains($0.id) }
                .sorted { $0.name < $1.name }
            
            ForEach(selectedParticipants) { participant in
                HStack {
                    Text(participant.name.prefix(1))
                        .font(.caption)
                        .fontWeight(.medium)
                        .frame(width: 24, height: 24)
                        .background(group.displayColor.opacity(0.2))
                        .foregroundStyle(group.displayColor)
                        .clipShape(Circle())
                    
                    Text(participant.name)
                        .foregroundStyle(Color.primary)
                    
                    Spacer()
                    
                    TextField(splitInputPlaceholder(), text: splitInputBinding(for: participant.id))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(group.displayColor.opacity(0.3), lineWidth: 0.5)
                        )
                        .foregroundStyle(Color.primary)
                        .frame(width: 100)
                }
                .padding(.vertical, 4)
            }
            
            if let sumInfo = splitInputSumInfo() {
                HStack {
                    Image(systemName: "sum")
                        .foregroundStyle(group.displayColor.opacity(0.7))
                        .font(.caption)
                    Text(sumInfo)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.secondary)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6).opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(group.displayColor.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.top, 8)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.9, anchor: .top).combined(with: .opacity),
            removal: .opacity.combined(with: .scale(scale: 0.9, anchor: .top))
        ))
    }
}

struct ParticipantAvatar: View {
    let member: Person
    let isSelected: Bool
    let accentColor: Color

    @Environment(\.colorScheme) var colorScheme

    private var avatarBackgroundColor: Color {
        isSelected ? accentColor.opacity(0.3) : Color(.systemGray5)
    }

    private var avatarInitialForegroundColor: Color {
        if isSelected {
            return accentColor
        } else {
            return Color.primary
        }
    }
    
    private var constantContrastBorderColor: Color {
        Color(UIColor.separator)
    }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(avatarBackgroundColor)
                Circle()
                    .strokeBorder(constantContrastBorderColor, lineWidth: 0.8)
                Text(member.name.prefix(1))
                    .font(isSelected ? .title3 : .body)
                    .fontWeight(.medium)
                    .foregroundColor(avatarInitialForegroundColor)
                if isSelected {
                    Circle()
                        .strokeBorder(accentColor, lineWidth: 2.0)
                }
            }
            .frame(width: isSelected ? 50 : 45, height: isSelected ? 50 : 45)
            Text(member.name)
                .font(.caption)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(isSelected ? accentColor : Color.primary)
        }
        .opacity(isSelected ? 1.0 : 0.85)
        .animation(.spring(), value: isSelected)
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
    
    let group = Group(name: "Comunidad del Anillo", colorHex: Color.green.toHex()) // Asumiendo que Color.green.toHex() es válido
    
    // Añadir miembros al contexto y al grupo
    container.mainContext.insert(p1)
    container.mainContext.insert(p2)
    container.mainContext.insert(p3)
    
    group.members = [p1, p2, p3]
    container.mainContext.insert(group) // Insertar el grupo después de asignar miembros si la relación se maneja así
    
    // Asegúrate que Color("AppBackground"), Color("ColorButton"), etc., estén en tus Assets
    // o el preview podría no verse como esperas o dar colores por defecto.

    return AddExpenseView(group: group)
        .modelContainer(container)
}
