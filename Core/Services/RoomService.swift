// Fichero: RondaApp/Core/Services/RoomService.swift

import Foundation
import Firebase
import FirebaseFirestore
import Combine

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
    
    // ✅ FUNCIÓN CORREGIDA: Ahora inicializa la puntuación del propietario.
    func createRoom(title: String, description: String?, owner: User) async throws -> String {
        let newRoom = Room(
            title: title,
            description: description,
            photoURL: nil,
            ownerId: owner.uid,
            memberIds: [owner.uid],
            // ¡Clave! Inicializamos el mapa de puntuaciones con el propietario.
            scores: [owner.uid: 0]
        )
        
        let documentRef = try roomsCollection.addDocument(from: newRoom)
        return documentRef.documentID
    }
    
    func updateRoomPhotoURL(roomId: String, url: String) async throws {
        try await roomsCollection.document(roomId).updateData(["photoURL": url])
    }
    
    func leaveRoom(_ room: Room, userId: String) async throws {
        guard let roomId = room.id else { throw URLError(.badURL) }
        
        // Eliminamos al usuario de la lista de miembros y de sus puntuaciones.
        try await roomsCollection.document(roomId).updateData([
            "memberIds": FieldValue.arrayRemove([userId]),
            // Usamos FieldValue.delete() para eliminar la clave del mapa.
            "scores.\(userId)": FieldValue.delete()
        ])
    }
    
    func listenToRoomUpdates(roomId: String) -> AnyPublisher<Room, Error> {
        let subject = PassthroughSubject<Room, Error>()
        
        let listener = roomsCollection.document(roomId)
            .addSnapshotListener { documentSnapshot, error in
                guard let document = documentSnapshot else {
                    if let error = error { subject.send(completion: .failure(error)) }
                    return
                }
                
                do {
                    let room = try document.data(as: Room.self)
                    subject.send(room)
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        
        return subject.handleEvents(receiveCancel: {
            listener.remove()
        }).eraseToAnyPublisher()
    }
    
    // ✅ FUNCIÓN MEJORADA: Ahora es más segura.
    func addDrinkForUser(userId: String, in room: Room) async throws {
        guard let roomId = room.id else { throw URLError(.badURL) }
        
        let roomRef = roomsCollection.document(roomId)
        
        // Se asegura de que el usuario esté en la sala antes de incrementar.
        // Si no está, lo añade con 1 punto. Si ya está, le suma 1.
        try await roomRef.setData([
            "scores": [userId: FieldValue.increment(Int64(1))]
        ], merge: true)
    }
}
