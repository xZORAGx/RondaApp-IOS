//
//  StorageService.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 11/7/25.
//

//  RondaApp/Core/Services/StorageService.swift

import Foundation
import FirebaseStorage
import UIKit // Usaremos UIKit para comprimir la imagen

class StorageService {
    
    static let shared = StorageService()
    private let storage = Storage.storage().reference()
    
    private var imagesRef: StorageReference {
        storage.child("room_images")
    }
    
    private init() {}
    
    // Sube una imagen y devuelve la URL de descarga
    func uploadRoomImage(imageData: Data, roomId: String) async throws -> URL {
        let imageRef = imagesRef.child("\(roomId).jpg")
        
        // Comprimimos la imagen para ahorrar espacio y costes
        guard let compressedImage = UIImage(data: imageData)?.jpegData(compressionQuality: 0.4) else {
            throw URLError(.cannotDecodeContentData)
        }
        
        let _ = try await imageRef.putDataAsync(compressedImage)
        let downloadURL = try await imageRef.downloadURL()
        return downloadURL
    }
    func uploadProfileImage(imageData: Data, userId: String) async throws -> URL {
            let profileImagesRef = storage.child("profile_images/\(userId).jpg")
            
            // Usamos metadatos para indicar que es una imagen JPEG
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            
            let _ = try await profileImagesRef.putDataAsync(imageData, metadata: metadata)
            let downloadURL = try await profileImagesRef.downloadURL()
            return downloadURL
        }
    
    func uploadChatMedia(data: Data, roomId: String, messageId: String, mediaType: MediaType) async throws -> URL {
           // Nos aseguramos de que solo se intente subir un audio.
           guard mediaType == .audio else {
               throw URLError(.badURL, userInfo: [NSLocalizedDescriptionKey: "Intento de subir un tipo de media no permitido."])
           }
           
           // La extensión siempre será "m4a" para nuestros audios.
           let fileExtension = "m4a"
           
           let mediaRef = storage.child("chat_media").child(roomId).child("\(messageId).\(fileExtension)")
           
           let metadata = StorageMetadata()
           metadata.contentType = "audio/m4a" // Es buena práctica especificar el tipo de contenido
           
           let _ = try await mediaRef.putDataAsync(data, metadata: metadata)
           let downloadURL = try await mediaRef.downloadURL()
           return downloadURL
       }
   }
    

