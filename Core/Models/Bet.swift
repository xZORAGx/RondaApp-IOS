// Fichero: RondaApp/Core/Models/Bet.swift
// ✅ VERSIÓN ACTUALIZADA

import Foundation
import FirebaseFirestore

enum BetStatus: String, Codable {
    case pending = "Pendiente"
    case won = "Ganada"
    case lost = "Perdida"
    case cancelled = "Cancelada"
}

struct Bet: Identifiable, Codable, Hashable {
    // ✅ Se añade @DocumentID para que se mapee automáticamente
    @DocumentID var id: String?
    
    var title: String
    var targetUserId: String
    var proposerUserId: String
    var odds: Double
    var deadline: Timestamp
    var status: BetStatus = .pending
    var wagers: [String: Int] = [:]
    
    // Este campo será usado por la política de TTL de Firestore
    var resolvedAt: Timestamp?
}
