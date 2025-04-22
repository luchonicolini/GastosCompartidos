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
    @State private var showingErrorAlert = false
    @State private var alertMessage = ""
    @State private var errorDetails = ""
    @State private var isAnimating = false

    @Query(sort: \Group.creationDate, order: .reverse) private var groups: [Group]

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                VStack {
                    if groups.isEmpty {
                        ContentUnavailableView(
                            "No hay grupos",
                            systemImage: "person.3.sequence.fill",
                            description: Text("Toca '+' para añadir tu primer grupo.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.9)))
                        .accessibilityLabel("No hay grupos. Toca el botón más para añadir tu primer grupo.")
                    } else {
                        List {
                            ForEach(groups) { group in
                                NavigationLink(value: group) {
                                    GroupRowView(group: group)
                                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .scale(scale: 0.95)))
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                                .swipeActions {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            deleteItem(group)
                                        }
                                    } label: {
                                        Label("Eliminar", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .toolbar {
                            ToolbarItem(placement: .navigationBarLeading) {
                                if !groups.isEmpty {
                                    EditButton()
                                }
                            }
                        }
                    }
                }

                Button {
                    showingAddGroupSheet = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title.weight(.semibold))
                        .padding()
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .clipShape(Circle())
                        .shadow(radius: 5, x: 0, y: 4)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                }
                .padding()
                .transition(reduceMotion ? .opacity : .scale.combined(with: .opacity))
                .animation(reduceMotion ? nil : .snappy, value: groups.isEmpty)
                .accessibilityLabel("Añadir nuevo grupo")
                .onAppear {
                    if !reduceMotion {
                        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                            isAnimating = true
                        }
                    }
                }

            }
            .navigationTitle("Mis Grupos")
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
            .animation(reduceMotion ? nil : .snappy, value: groups.isEmpty)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        viewModel.deleteGroup(at: offsets, for: groups, context: modelContext)
    }
    
    private func deleteItem(_ group: Group) {
        modelContext.delete(group)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Group.self, Person.self, Expense.self], inMemory: true)
}
