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
    
    func createRoom(title: String, description: String?, owner: User) async throws -> String {
        // Creamos las dos bebidas por defecto
        let defaultDrinks = [
            Drink(name: "Cerveza", points: 1, emoji: "🍺"),
            Drink(name: "Calimocho", points: 1, emoji: "🍷")
        ]
        
        // ✅ ORDEN CORREGIDO
        let newRoom = Room(
            title: title,
            description: description,
            photoURL: nil,
            ownerId: owner.uid, // <-- Esta línea va primero
            invitationCode: generateInvitationCode(), // <-- Y esta después
            memberIds: [owner.uid],
            drinks: defaultDrinks,
            scores: [owner.uid: [:]]
        )
        
        let documentRef = try roomsCollection.addDocument(from: newRoom)
        return documentRef.documentID
    }
    
    func updateRoomPhotoURL(roomId: String, url: String) async throws {
        try await roomsCollection.document(roomId).updateData(["photoURL": url])
    }
    
    func leaveRoom(_ room: Room, userId: String) async throws {
        guard let roomId = room.id else { throw URLError(.badURL) }
        
        try await roomsCollection.document(roomId).updateData([
            "memberIds": FieldValue.arrayRemove([userId]),
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
    
    func addDrinkForUser(userId: String, drinkId: String, in room: Room) async throws {
        guard let roomId = room.id else { throw URLError(.badURL) }
        
        let roomRef = roomsCollection.document(roomId)
        
        // La clave para actualizar un campo anidado es usar "notación de punto"
        let scoreFieldPath = "scores.\(userId).\(drinkId)"
        
        // Usamos setData con merge:true para asegurarnos de que el sub-mapa del usuario existe
        try await roomRef.setData([
            "scores": [userId: [drinkId: FieldValue.increment(Int64(1))]]
        ], merge: true)
    }
    
    func addCustomDrink(_ drink: Drink, toRoomId roomId: String) async throws {
        guard let drinkData = try? Firestore.Encoder().encode(drink) else {
            throw NSError(domain: "AppError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error al codificar la bebida"])
        }
        
        try await roomsCollection.document(roomId).updateData([
            "drinks": FieldValue.arrayUnion([drinkData])
        ])
    }
    
    func joinRoom(withCode code: String, userId: String) async throws {
        let query = roomsCollection.whereField("invitationCode", isEqualTo: code).limit(to: 1)
        let snapshot = try await query.getDocuments()
        
        guard let document = snapshot.documents.first else {
            throw NSError(domain: "RoomService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No se ha encontrado ninguna sala con ese código."])
        }
        
        let roomId = document.documentID
        
        try await roomsCollection.document(roomId).updateData([
            "memberIds": FieldValue.arrayUnion([userId]),
            "scores.\(userId)": [:] // Inicializa el mapa de bebidas del nuevo usuario como vacío
        ])
    }
    
    private func generateInvitationCode(length: Int = 6) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    func updateDrinks(forRoomId roomId: String, with newDrinks: [Drink]) async throws {
        // Convertimos el array de structs a un array de diccionarios que Firebase entiende
        let drinksData = try newDrinks.map { try Firestore.Encoder().encode($0) }
        
        try await roomsCollection.document(roomId).updateData([
            "drinks": drinksData
        ])
    }
    
}
