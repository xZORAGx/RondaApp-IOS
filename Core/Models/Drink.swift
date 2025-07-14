//
//  Drink.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

// Fichero: RondaApp/Core/Models/Drink.swift

import Foundation

// Hacemos que sea Hashable para poder usarlo en colecciones y Codable para Firebase.
struct Drink: Identifiable, Codable, Hashable {
    var id: String = UUID().uuidString // ID único para cada tipo de bebida
    var name: String
    var points: Int
    var emoji: String? // ✅ NUEVA PROPIEDAD para el emoji

}
