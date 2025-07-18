// Fichero: RondaApp/Core/Models/Duel.swift

import Foundation
import FirebaseFirestore

// ✅ ENUM SIMPLIFICADO: Eliminamos .pending y .finished que son redundantes.
enum DuelStatus: String, Codable {
    case awaitingAcceptance = "Esperando Respuesta"
    case inProgress = "En Progreso"
    case inPoll = "En Votación"
    case resolved = "Resuelto"
}

struct Duel: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    var title: String
    var description: String?
    
    var challengerId: String
    var opponentId: String
    
    var wager: Int
    
    var startTime: Timestamp
    var endTime: Timestamp
    
    // El estado inicial por defecto es el correcto.
    var status: DuelStatus = .awaitingAcceptance
    
    var winnerId: String?
    var pollId: String?
    var resolvedAt: Timestamp?
}
