// Fichero: RondaApp/Core/Services/StorageService.swift
// ✅ VERSIÓN ACTUALIZADA CON UPLOAD DE IMAGEN PARA CHECK-INS

import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    
    // --- Referencias a carpetas en Storage ---
    private var roomImagesRef: StorageReference { storage.child("room_images") }
    private var profileImagesRef: StorageReference { storage.child("profile_images") }
    private var chatMediaRef: StorageReference { storage.child("chat_media") }
    // ✅ NUEVA REFERENCIA
    private var checkInImagesRef: StorageReference { storage.child("checkin_images") }
    
    private init() {}
    
    // --- Funciones existentes (sin cambios) ---
    
    func uploadRoomImage(imageData: Data, roomId: String) async throws -> URL {
        let imageRef = roomImagesRef.child("\(roomId).jpg")
        guard let compressedImage = UIImage(data: imageData)?.jpegData(compressionQuality: 0.4) else {
            throw URLError(.cannotDecodeContentData)
        }
        let _ = try await imageRef.putDataAsync(compressedImage)
        return try await imageRef.downloadURL()
    }

    func uploadProfileImage(imageData: Data, userId: String) async throws -> URL {
        let profileImageRef = profileImagesRef.child("\(userId).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        let _ = try await profileImageRef.putDataAsync(imageData, metadata: metadata)
        return try await profileImageRef.downloadURL()
    }

    func uploadChatMedia(data: Data, roomId: String, messageId: String, mediaType: MediaType) async throws -> URL {
        guard mediaType == .audio else {
            throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Tipo de media no permitido para esta función."])
        }
        let fileExtension = "m4a"
        let mediaRef = chatMediaRef.child(roomId).child("\(messageId).\(fileExtension)")
        let metadata = StorageMetadata()
        metadata.contentType = "audio/m4a"
        let _ = try await mediaRef.putDataAsync(data, metadata: metadata)
        return try await mediaRef.downloadURL()
    }
    
    // --- ✅ NUEVA FUNCIÓN AÑADIDA ---
    
    /// Sube la imagen de un check-in y devuelve su URL de descarga.
    /// - Parameters:
    ///   - data: Los datos de la imagen en formato Data.
    ///   - roomId: El ID de la sala donde se realiza el check-in.
    ///   - checkInId: El ID del documento del check-in.
    /// - Returns: La URL pública de la imagen.
    func uploadCheckInImage(data: Data, roomId: String, checkInId: String) async throws -> URL {
        let imageRef = checkInImagesRef.child(roomId).child("\(checkInId).jpg")
        
        // Comprimimos la imagen para que la subida sea más rápida y ocupe menos.
        guard let compressedData = UIImage(data: data)?.jpegData(compressionQuality: 0.5) else {
            throw URLError(.cannotDecodeContentData, userInfo: [NSLocalizedDescriptionKey: "No se pudo comprimir la imagen."])
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let _ = try await imageRef.putDataAsync(compressedData, metadata: metadata)
        return try await imageRef.downloadURL()
    }
}
