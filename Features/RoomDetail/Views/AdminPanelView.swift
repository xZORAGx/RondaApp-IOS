// Fichero: RondaApp/Features/RoomDetail/Views/AdminPanelView.swift

import SwiftUI

struct AdminPanelView: View {
    
    @ObservedObject var viewModel: RoomDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var drinkToEdit: Drink?
    
    var body: some View {
        NavigationView {
            List {
                ForEach($viewModel.room.drinks) { $drink in
                    Button(action: { drinkToEdit = drink }) {
                        HStack {
                            Text(drink.emoji ?? "🥤")
                            Text(drink.name)
                            Spacer()
                            Text("\(drink.points) pts")
                                .foregroundColor(.secondary)
                        }
                        .foregroundColor(.primary)
                    }
                }
                .onDelete(perform: deleteDrink)
            }
            .navigationTitle("Panel de Admin")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.addNewDrink()
                        // Abrimos la hoja de edición para la última bebida que acabamos de crear.
                        drinkToEdit = viewModel.room.drinks.last
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(item: $drinkToEdit) {
                // Al cerrar la hoja de edición (AddEditDrinkView), guardamos todos los cambios.
                // Esto asegura que tanto las ediciones como las adiciones se persistan.
                Task {
                    try? await viewModel.saveDrinkChanges()
                }
            } content: { drink in
                // Buscamos el índice de la bebida para pasar un Binding seguro.
                if let index = viewModel.room.drinks.firstIndex(where: { $0.id == drink.id }) {
                    AddEditDrinkView(drink: $viewModel.room.drinks[index])
                }
            }
        }
    }
    
    private func deleteDrink(at offsets: IndexSet) {
        Task {
            await viewModel.deleteDrink(at: offsets)
        }
    }
}
