//
//  DrinkSelectionView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

// Fichero: DrinkSelectionView.swift

import SwiftUI

struct DrinkSelectionView: View {
    let drinks: [Drink]
    let onSelectDrink: (Drink) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List(drinks) { drink in
                Button(action: {
                    onSelectDrink(drink)
                }) {
                    HStack {
                        Text(drink.emoji ?? "🥤")
                        Text(drink.name)
                            .font(.headline)
                        Spacer()
                        Text("\(drink.points) pt\(drink.points > 1 ? "s" : "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Selecciona una Bebida")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
}
