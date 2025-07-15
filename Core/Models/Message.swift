// Fichero: RondaApp/Core/Models/Message.swift

import Foundation
import FirebaseFirestore

enum MediaType: String, Codable {
    case text
    case audio
}

struct Message: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let authorId: String
    let timestamp: Timestamp
    
    let mediaType: MediaType
    
    // Contenido condicional
    var textContent: String?
    var mediaURL: String?
    var duration: TimeInterval?
    
    // ✅ NUEVA PROPIEDAD para la onda de audio
    var waveformSamples: [Float]?
}
