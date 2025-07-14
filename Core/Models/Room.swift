// Fichero: RondaApp/Core/Models/Room.swift

import Foundation
import FirebaseFirestore // ¡Asegúrate de que este import esté presente!

struct Room: Identifiable, Codable, Equatable {
    
    @DocumentID var id: String?
    
    let title: String
    var description: String?
    var photoURL: String?
    let ownerId: String
    var invitationCode: String?
    var memberIds: [String]
    
    // ✅ ESTRUCTURA CORREGIDA
    var drinks: [Drink]
    var scores: [String: [String: Int]] // Esta es la única línea de 'scores' que debe existir
    
    static func == (lhs: Room, rhs: Room) -> Bool {
        lhs.id == rhs.id
    }
}
