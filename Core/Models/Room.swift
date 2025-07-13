//  RondaApp/Core/Models/Room.swift

import Foundation
import FirebaseFirestore

struct Room: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    
    var title: String
    var description: String?
    var photoURL: String? // <-- NUEVO CAMPO
    var ownerId: String
    var memberIds: [String]
}
