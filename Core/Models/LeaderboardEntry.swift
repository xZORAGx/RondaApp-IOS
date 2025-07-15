//
//  LeaderboardEntry.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

import Foundation

struct LeaderboardEntry: Identifiable, Equatable {
    var id: String { user.uid }
    
    let user: User
    let score: Int // Mantenemos la puntuación total
    let userScores: [String: Int] // ✅ NUEVO: Llevamos el desglose de bebidas [DrinkID: Count]
}
