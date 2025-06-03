//
//  HomeView.swift
//  ContextoGestion
//
//  Created by Luciano Nicolini on 22/04/2025.
//

import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var viewModel = GroupListViewModel()
    @State private var showingAddGroupSheet = false
    @State private var showingEditGroupSheet = false
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    @State private var errorDetails = ""
    @State private var isAnimating = false
    @State private var titleOpacity: Double = 0
    @State private var contentOffset: CGFloat = 20
    @State private var particlesAnimated = false
    
    // Estados para confirmación de eliminación
    @State private var showingDeleteAlert = false
    @State private var groupToDelete: Group?
    @State private var groupToEdit: Group?

    @Query(sort: \Group.creationDate, order: .reverse) private var groups: [Group]

    var body: some View {
        NavigationStack {
            ZStack {
                // Fondo con gradiente sofisticado
                backgroundGradient
                    .ignoresSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header personalizado con animaciones
                    customHeader
                    
                    // Contenido principal
                    mainContent
                }
                
                // Botón flotante mejorado
                floatingActionButton
            }
            .navigationTitle("")
            .navigationBarHidden(true)
            .navigationDestination(for: Group.self) { group in
                GroupDetailView(group: group)
            }
            .sheet(isPresented: $showingAddGroupSheet) {
                AddGroupView { groupName, iconName, colorHex in
                    do {
                        try viewModel.addGroup(
                            name: groupName,
                            iconName: iconName,
                            colorHex: colorHex,
                            context: modelContext
                        )
                    } catch let error as LocalizedError {
                        self.alertMessage = error.errorDescription ?? "Error al añadir grupo."
                        self.errorDetails = error.failureReason ?? ""
                        self.showingErrorAlert = true
                    } catch {
                        self.alertMessage = "Error inesperado al añadir grupo."
                        self.errorDetails = error.localizedDescription
                        self.showingErrorAlert = true
                    }
                }
            }
            .sheet(item: $groupToEdit) { group in
                EditGroupView(group: group) { groupName, iconName, colorHex in
                    do {
                        try updateGroup(
                            group: group,
                            name: groupName,
                            iconName: iconName,
                            colorHex: colorHex
                        )
                    } catch let error as LocalizedError {
                        self.alertMessage = error.errorDescription ?? "Error al actualizar grupo."
                        self.errorDetails = error.failureReason ?? ""
                        self.showingErrorAlert = true
                    } catch {
                        self.alertMessage = "Error inesperado al actualizar grupo."
                        self.errorDetails = error.localizedDescription
                        self.showingErrorAlert = true
                    }
                }
            }
            .alert("Error", isPresented: $showingErrorAlert) {
                Button("OK") { }
            } message: {
                VStack {
                    Text(alertMessage)
                    if !errorDetails.isEmpty {
                        Text(errorDetails)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            // Alert de confirmación para eliminar grupo
            .alert("Eliminar Grupo", isPresented: $showingDeleteAlert) {
                Button("Cancelar", role: .cancel) {
                    groupToDelete = nil
                }
                Button("Eliminar", role: .destructive) {
                    if let group = groupToDelete {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            deleteGroup(group)
                        }
                    }
                    groupToDelete = nil
                }
            } message: {
                if let group = groupToDelete {
                    Text("¿Estás seguro de que quieres eliminar el grupo '\(group.name)'? Esta acción no se puede deshacer.")
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8)) {
                    titleOpacity = 1
                    contentOffset = 0
                }
                
                // Animación del botón flotante - solo una vez
                if !reduceMotion {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isAnimating = true
                    }
                }
                
                // Animar partículas solo una vez
                if !particlesAnimated && !reduceMotion {
                    withAnimation(.easeInOut(duration: 2.0)) {
                        particlesAnimated = true
                    }
                }
            }
        }
    }
    
    // MARK: - Background
    
    @ViewBuilder
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color("AppBackground"),
                Color("AppBackground").opacity(0.95),
                Color("AppBackground").opacity(0.9)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(
            // Efecto de partículas sutiles - animación única
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(Color.primary.opacity(0.02))
                    .frame(width: CGFloat.random(in: 100...200))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(particlesAnimated ? 1.1 : 0.8)
                    .opacity(particlesAnimated ? 0.8 : 0.2)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .delay(Double(i) * 0.3),
                        value: particlesAnimated
                    )
            }
        )
    }
    
    // MARK: - Custom Header
    
    @ViewBuilder
    private var customHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Mis Grupos")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    if !groups.isEmpty {
                        Text("\(groups.count) \(groups.count == 1 ? "grupo" : "grupos")")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
                
                Spacer()
            }
            
            // Línea decorativa
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.clear,
                                Color.primary.opacity(0.3),
                                Color.primary.opacity(0.1),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 1)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .opacity(titleOpacity)
        .offset(y: -contentOffset)
        .animation(.spring(response: 0.8, dampingFraction: 0.8), value: groups.count)
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        if groups.isEmpty {
            emptyStateView
        } else {
            groupsList
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Ícono con animación única y sutil
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(isAnimating ? 1.02 : 1.0) // Escala más sutil
                
                Circle()
                    .stroke(Color.primary.opacity(0.2), lineWidth: 2)
                    .frame(width: 120, height: 120)
                
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(Color.primary.opacity(0.6))
            }
            .animation(.easeInOut(duration: 0.8), value: isAnimating)
            
            VStack(spacing: 12) {
                Text("No hay grupos")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Toca '+' para añadir tu primer grupo.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .opacity(titleOpacity)
        .offset(y: contentOffset)
        .transition(
            reduceMotion ?
                .opacity :
                .opacity.combined(with: .scale(scale: 0.9).combined(with: .move(edge: .bottom)))
        )
        .accessibilityLabel("No hay grupos. Toca el botón más para añadir tu primer grupo.")
    }
    
    @ViewBuilder
    private var groupsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    NavigationLink(value: group) {
                        GroupRowView(group: group)
                            .transition(
                                reduceMotion ?
                                    .opacity :
                                    .opacity.combined(with: .scale(scale: 0.95).combined(with: .move(edge: .bottom)))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                    // Context Menu para opciones
                    .contextMenu {
                        Button {
                            groupToEdit = group
//                            DispatchQueue.main.async {
//                                showingEditGroupSheet = true
//                            }
                        } label: {
                            Label("Editar Grupo", systemImage: "pencil")
                        }
                        
                        Button(role: .destructive) {
                            groupToDelete = group
                            showingDeleteAlert = true
                        } label: {
                            Label("Eliminar Grupo", systemImage: "trash")
                        }
                    }
                    // Swipe Actions para eliminar
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            groupToDelete = group
                            showingDeleteAlert = true
                        } label: {
                            Label("Eliminar", systemImage: "trash.fill")
                        }
                        .tint(.red)
                    }
                    // Swipe Actions para editar
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            groupToEdit = group
                            showingEditGroupSheet = true
                        } label: {
                            Label("Editar", systemImage: "pencil.circle.fill")
                        }
                        .tint(.blue)
                    }
                    .onAppear {
                        // Animación escalonada para la aparición de elementos
                        if !reduceMotion {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double(index) * 0.1)) {
                                // Trigger para animaciones
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .padding(.bottom, 100) // Espacio para el botón flotante
        }
        .opacity(titleOpacity)
        .offset(y: contentOffset)
        .scrollIndicators(.hidden)
    }
    
    // MARK: - Floating Action Button
    
    @ViewBuilder
    private var floatingActionButton: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button {
                    showingAddGroupSheet = true
                } label: {
                    ZStack {
                        // Sombra externa
                        Circle()
                            .fill(Color.black.opacity(0.15))
                            .frame(width: 62, height: 62)
                            .offset(y: 4)
                        
                        // Fondo principal con gradiente
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(Color.primaryText),
                                        Color(Color.primaryText).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        // Borde sutil
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            .frame(width: 60, height: 60)
                        
                        // Ícono
                        Image(systemName: "plus")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Color.appBackground)
                    }
                    .scaleEffect(isAnimating ? 1.0 : 0.9)
                    .shadow(
                        color: Color(Color.primaryText).opacity(0.3),
                        radius: isAnimating ? 10 : 6,
                        x: 0,
                        y: isAnimating ? 5 : 3
                    )
                }
                .accessibilityLabel("Añadir nuevo grupo")
                .transition(
                    reduceMotion ?
                        .opacity :
                        .scale.combined(with: .opacity.combined(with: .move(edge: .bottom)))
                )
                .animation(.spring(response: 0.6, dampingFraction: 0.7), value: isAnimating)
            }
        }
        .padding(.trailing, 24)
        .padding(.bottom, 34)
        .opacity(titleOpacity)
    }

    // MARK: - Helper Methods
    
    private func deleteItems(offsets: IndexSet) {
        viewModel.deleteGroup(at: offsets, for: groups, context: modelContext)
    }
    
    private func deleteGroup(_ group: Group) {
        modelContext.delete(group)
        
        // Guardar cambios inmediatamente
        do {
            try modelContext.save()
        } catch {
            print("Error al guardar después de eliminar grupo: \(error)")
        }
    }
    
    private func updateGroup(group: Group, name: String, iconName: String, colorHex: String) throws {
        group.name = name
        group.iconName = iconName
        group.colorHex = colorHex
        
        do {
            try modelContext.save()
        } catch {
            throw error
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Group.self, Person.self, Expense.self], inMemory: true)
}
