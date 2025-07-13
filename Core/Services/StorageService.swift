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
}
