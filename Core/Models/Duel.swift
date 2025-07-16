//
//  Duel.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 16/7/25.
//

// Fichero: RondaApp/Core/Models/Duel.swift

import Foundation
import FirebaseFirestore

enum DuelStatus: String, Codable {
    case pending = "Pendiente"
    case challengerWon = "Ganó Retador"
    case opponentWon = "Ganó Oponente"
    case draw = "Empate"
    case inPoll = "En Votación" // Nuevo estado para la encuesta
}

struct Duel: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    var title: String
    var description: String?
    var wager: Int // Créditos que se apuestan (cada uno)
    var challengerId: String // Quién reta
    var opponentId: String // El retado
    var judgeId: String // El juez
    var status: DuelStatus = .pending
    var pollId: String? // ID de la encuesta en el chat si se crea
}
