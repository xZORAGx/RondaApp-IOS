//  RondaApp/Core/Services/RoomService.swift

import Foundation
import Firebase
import FirebaseFirestore

class RoomService {
    
    static let shared = RoomService()
    private let db = Firestore.firestore()
    
    private var roomsCollection: CollectionReference {
        return db.collection("rooms")
    }
    
    private init() {}
    
    func fetchRooms(forUser userId: String) async throws -> [Room] {
        let snapshot = try await roomsCollection
            .whereField("memberIds", arrayContains: userId)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Room.self) }
    }
    
    // Esta función ahora devuelve el ID de la sala creada
    func createRoom(title: String, description: String?, owner: User) async throws -> String {
        let newRoom = Room(
            title: title,
            description: description,
            photoURL: nil, // La foto se añade después
            ownerId: owner.uid,
            memberIds: [owner.uid]
        )
        
        let documentRef = try roomsCollection.addDocument(from: newRoom)
        return documentRef.documentID
    }
    
    // Nueva función para actualizar la URL de la foto
    func updateRoomPhotoURL(roomId: String, url: URL) async throws {
        try await roomsCollection.document(roomId).updateData(["photoURL": url.absoluteString])
    }
}
