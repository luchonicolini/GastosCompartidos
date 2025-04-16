//
//  GroupListView.swift
//  GastosCompartidos
//
//  Created by Luciano Nicolini on 14/04/2025.
//


import SwiftUI
import SwiftData

struct GroupListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = GroupListViewModel()
    @State private var showingAddGroupSheet = false

    @Query(sort: \Group.creationDate, order: .reverse) private var groups: [Group]

    var body: some View {
        NavigationStack {
            // Contenido principal: O la lista o la vista de "no disponible"
            VStack { // Usar VStack como contenedor genérico si es necesario
                if groups.isEmpty {
                    ContentUnavailableView(
                        "No hay grupos todavía",
                        systemImage: "person.3.sequence.fill",
                        description: Text("Crea tu primer grupo para empezar a compartir gastos.")
                    )
                } else {
                    List {
                        ForEach(groups) { group in
                            // Error 2 corregido al hacer público el init de GroupDetailView
                            NavigationLink(value: group) { // Usar NavigationLink(value:) para navegación basada en datos
                                HStack {
                                    Image(systemName: "person.3")
                                    Text(group.name)
                                    Spacer()
                                    Text("\(group.members?.count ?? 0) miembros")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { indexSet in
                            viewModel.deleteGroup(at: indexSet, for: groups, context: modelContext)
                        }
                    }
                    // Aplicar EditButton a la List si no está vacía
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) { EditButton() }
                    }
                }
            }
            // Error 3 Corregido: .navigationTitle aplicado después del if/else
            .navigationTitle("Mis Grupos")
            // Error 1 Corregido: Toolbar movido fuera del List pero dentro de NavigationStack
            .toolbar {
                 // Botón de añadir siempre visible en la barra de navegación
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddGroupSheet = true
                    } label: {
                        Label("Añadir Grupo", systemImage: "plus.circle.fill")
                    }
                }
                // EditButton se mueve al toolbar de la List arriba para que solo aparezca si hay lista
            }
            // Definir el destino de la navegación basada en datos
            .navigationDestination(for: Group.self) { group in
                 GroupDetailView(group: group)
            }
            .sheet(isPresented: $showingAddGroupSheet) {
                AddGroupView { groupName in
                    viewModel.addGroup(name: groupName, context: modelContext)
                }
            }
        } // Fin NavigationStack
    }
}


#Preview {
    GroupListView()
}
