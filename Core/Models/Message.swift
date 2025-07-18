// Fichero: RondaApp/Core/Models/Message.swift
// ✅ VERSIÓN ACTUALIZADA PARA CHECK-INS

import Foundation
import FirebaseFirestore

// ✅ 1. AÑADIMOS EL CASO '.checkIn' A NUESTRO ENUM
enum MediaType: String, Codable {
    case text
    case audio
    case poll
    case checkIn // Nuevo tipo para mostrar un "momento" en el chat
}

struct Message: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let authorId: String
    let timestamp: Timestamp
    
    let mediaType: MediaType
    
    // --- Contenido Condicional ---
    
    // Para .text
    var textContent: String?
    
    // Para .audio
    var mediaURL: String?
    var duration: TimeInterval?
    var waveformSamples: [Float]?
    
    // Para .poll
    var pollId: String?
    var duelId: String?

    // ✅ 2. AÑADIMOS LA PROPIEDAD PARA VINCULAR CON UN CHECK-IN
    // Cuando el mediaType sea .checkIn, este campo tendrá el ID
    // del documento en la colección 'checkIns'.
    var checkInId: String?
}
