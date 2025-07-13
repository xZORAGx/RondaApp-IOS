// Fichero: RondaApp/Core/Models/Room.swift

import Foundation
import FirebaseFirestore // ¡Asegúrate de que este import esté presente!

struct Room: Identifiable, Codable {
    
    // ✅ ¡ESTA LÍNEA ES LA SOLUCIÓN MÁGICA!
    // Le dice a Firebase que ponga aquí el ID del documento automáticamente.
    @DocumentID var id: String?
    
    // El resto de tus propiedades
    let title: String
    var description: String?
    var photoURL: String?
    let ownerId: String
    var memberIds: [String]
    var scores: [String: Int]? // Es opcional porque al inicio puede no existir
    
    // Puedes añadir más propiedades aquí si las necesitas
}
