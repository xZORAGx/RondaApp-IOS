// Fichero: RondaApp/Features/RoomDetail/Views/AddEditDrinkView.swift

import SwiftUI

struct AddEditDrinkView: View {
    
    @Binding var drink: Drink
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detalles de la Bebida") {
                    TextField("Nombre (ej. Cerveza)", text: $drink.name)
                    TextField("Emoji (ej. 🍺)", text: Binding(
                        get: { drink.emoji ?? "" },
                        set: { drink.emoji = $0 }
                    ))
                    .frame(width: 50)
                }
                
                Section("Puntuación") {
                    Stepper("\(drink.points) puntos", value: $drink.points, in: 1...100)
                }
            }
            .navigationTitle(drink.name.isEmpty ? "Nueva Bebida" : "Editar Bebida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hecho") {
                        dismiss()
                    }
                    // El botón se activa solo si la bebida tiene un nombre.
                    .disabled(drink.name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}
