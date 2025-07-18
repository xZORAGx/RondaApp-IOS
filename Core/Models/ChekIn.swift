// Fichero: RondaApp/Core/Models/CheckIn.swift
// ✅ VERSIÓN COMPLETA CON EL CAMPO 'location'

import Foundation
import FirebaseFirestore

struct CheckIn: Identifiable, Codable {
    @DocumentID var id: String?
    
    let userId: String
    let roomId: String
    let drinkId: String
    let timestamp: Timestamp
    
    // --- Campos Opcionales ---
    var photoURL: String?
    var caption: String?
    var location: GeoPoint?     // ✅ ESTA ES LA PROPIEDAD QUE FALTABA
    
    // --- Campo para el Borrado Automático (TTL) ---
    var expiresAt: Timestamp
    
    // Inicializador que maneja el campo opcional 'location'
    init(
        userId: String,
        roomId: String,
        drinkId: String,
        photoURL: String? = nil,
        caption: String? = nil,
        location: GeoPoint? = nil // ✅ AÑADIDO AQUÍ
    ) {
        self.userId = userId
        self.roomId = roomId
        self.drinkId = drinkId
        self.timestamp = Timestamp(date: Date())
        self.photoURL = photoURL
        self.caption = caption
        self.location = location // ✅ AÑADIDO AQUÍ
        
        let oneWeekInSeconds: TimeInterval = 7 * 24 * 60 * 60
        self.expiresAt = Timestamp(date: Date().addingTimeInterval(oneWeekInSeconds))
    }
}
