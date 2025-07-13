//
//  LeaderboardEntry.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 13/7/25.
//

// Fichero: RondaApp/Core/Models/LeaderboardEntry.swift

import Foundation

// Este modelo nos ayudará a combinar los datos para la vista.
// Es Identifiable para poder usarlo en un ForEach.
struct LeaderboardEntry: Identifiable {
    var id: String { user.uid } // Usamos el uid del usuario como identificador
    
    let user: User
    let score: Int
}
