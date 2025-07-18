// Fichero: RondaApp/Core/Models/Message.swift
// ✅ VERSIÓN COMPLETA Y ACTUALIZADA

import Foundation
import FirebaseFirestore

// ✅ 1. AÑADIMOS EL CASO '.poll'
enum MediaType: String, Codable {
    case text
    case audio
    case poll // Nuevo tipo para encuestas
}

struct Message: Identifiable, Codable, Hashable {
    @DocumentID var id: String?
    let authorId: String
    let timestamp: Timestamp
    
    let mediaType: MediaType
    
    // Contenido condicional
    var textContent: String?
    var mediaURL: String? // Se mantiene para el audio
    var duration: TimeInterval?
    
    var waveformSamples: [Float]?
    
    // ✅ 2. AÑADIMOS LA PROPIEDAD PARA VINCULAR CON UNA ENCUESTA
    var pollId: String?
    var duelId: String?

}
