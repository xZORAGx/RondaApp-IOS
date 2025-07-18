//
//  Poll.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 17/7/25.
//

// Fichero: RondaApp/Core/Models/Poll.swift

import Foundation
import FirebaseFirestore

struct Poll: Identifiable, Codable {
    @DocumentID var id: String?
    
    var duelId: String      // Para saber a qué duelo pertenece
    var question: String    // Ej: "¿Quién ganó: David o Ana?"
    
    // [ID del Votado : [IDs de los que le han votado]]
    // Ej: ["david_id": ["ana_id", "pedro_id"], "ana_id": ["lucia_id"]]
    var votes: [String: [String]] = [:]
    
    var memberCountAtCreation: Int // Para saber cuándo se alcanza la mayoría
    
    // Este campo será usado por el TTL de la encuesta (24h)
    var expiresAt: Timestamp
}
