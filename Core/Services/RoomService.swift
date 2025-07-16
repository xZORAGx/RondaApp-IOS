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
    
    // --- LÓGICA DE APUESTAS REFACTORIZADA ---
    
    func listenToBets(inRoomId roomId: String) -> AnyPublisher<[Bet], Error> {
        let subject = PassthroughSubject<[Bet], Error>()
        
        let listener = roomsCollection.document(roomId).collection("bets")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    if let error = error { subject.send(completion: .failure(error)) }
                    return
                }
                
                let bets = documents.compactMap { try? $0.data(as: Bet.self) }
                subject.send(bets)
            }
        
        return subject.handleEvents(receiveCancel: { listener.remove() }).eraseToAnyPublisher()
    }

    func createBet(_ bet: Bet, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let newBetRef = roomRef.collection("bets").document(bet.id ?? UUID().uuidString)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let roomDocument: DocumentSnapshot
            do { try roomDocument = transaction.getDocument(roomRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }

            guard let room = try? roomDocument.data(as: Room.self) else {
                errorPointer?.pointee = NSError(domain: "AppError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo decodificar la sala."])
                return nil
            }
            
            let proposerId = bet.proposerUserId
            guard let initialWager = bet.wagers[proposerId],
                  let userCredits = room.userCredits[proposerId],
                  userCredits >= initialWager else {
                errorPointer?.pointee = NSError(domain: "AppError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Créditos insuficientes."])
                return nil
            }
            
            let newCredits = userCredits - initialWager
            transaction.updateData(["userCredits.\(proposerId)": newCredits], forDocument: roomRef)
            
            do {
                try transaction.setData(from: bet, forDocument: newBetRef)
            } catch let setDataError as NSError {
                errorPointer?.pointee = setDataError
                return nil
            }
            
            return nil
        }
    }

    func placeWager(betId: String, userId: String, amount: Int, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let betRef = roomRef.collection("bets").document(betId)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let roomDocument: DocumentSnapshot
            do { try roomDocument = transaction.getDocument(roomRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }

            guard let room = try? roomDocument.data(as: Room.self) else { return nil }
            
            guard let userCredits = room.userCredits[userId], userCredits >= amount else {
                errorPointer?.pointee = NSError(domain: "AppError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No tienes suficientes créditos."])
                return nil
            }
            
            let newCredits = userCredits - amount
            transaction.updateData(["userCredits.\(userId)": newCredits], forDocument: roomRef)
            transaction.updateData(["wagers.\(userId)": amount], forDocument: betRef)
            
            return nil
        }
    }

    // ✅ FUNCIÓN CORREGIDA
    func resolveBet(betId: String, newStatus: BetStatus, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let betRef = roomRef.collection("bets").document(betId)

        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let betDocument: DocumentSnapshot
            do { try betDocument = transaction.getDocument(betRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }
            
            guard let bet = try? betDocument.data(as: Bet.self) else { return nil }
            
            var creditChanges: [String: Any] = [:]
            
            if newStatus == .won {
                for (userId, wager) in bet.wagers {
                    let winnings = Int(Double(wager) * bet.odds)
                    creditChanges["userCredits.\(userId)"] = FieldValue.increment(Int64(winnings))
                }
            } else if newStatus == .cancelled {
                for (userId, wager) in bet.wagers {
                    creditChanges["userCredits.\(userId)"] = FieldValue.increment(Int64(wager))
                }
            }
            
            if !creditChanges.isEmpty {
                transaction.updateData(creditChanges, forDocument: roomRef)
            }
            
            // ✅ CORRECCIÓN CLAVE: Calculamos la fecha de expiración para el TTL
            let expirationDate = Date().addingTimeInterval(24 * 60 * 60) // 24 horas desde ahora
            let expirationTimestamp = Timestamp(date: expirationDate)
            
            transaction.updateData([
                "status": newStatus.rawValue,
                "resolvedAt": expirationTimestamp // Guardamos la fecha de borrado futura
            ], forDocument: betRef)
            
            return nil
        }
    }
    
    // --- FUNCIONES ORIGINALES (MANTENIDAS Y COMPLETAS) ---
    
    func fetchRooms(forUser userId: String) async throws -> [Room] {
        let snapshot = try await roomsCollection.whereField("memberIds", arrayContains: userId).getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Room.self) }
    }
    
    func createRoom(title: String, description: String?, owner: User) async throws -> String {
        let defaultDrinks = [Drink(name: "Cerveza", points: 1, emoji: "🍺"), Drink(name: "Calimocho", points: 1, emoji: "🍷")]
        let newRoom = Room(title: title, description: description, photoURL: nil, ownerId: owner.uid, invitationCode: generateInvitationCode(), memberIds: [owner.uid], drinks: defaultDrinks, scores: [owner.uid: [:]], userCredits: [owner.uid: 10000])
        let documentRef = try roomsCollection.addDocument(from: newRoom)
        return documentRef.documentID
    }
    
    func joinRoom(withCode code: String, userId: String) async throws {
        let query = roomsCollection.whereField("invitationCode", isEqualTo: code).limit(to: 1)
        let snapshot = try await query.getDocuments()
        guard let document = snapshot.documents.first else { throw URLError(.badServerResponse) }
        let roomId = document.documentID
        try await roomsCollection.document(roomId).updateData(["memberIds": FieldValue.arrayUnion([userId]), "scores.\(userId)": [:], "userCredits.\(userId)": 10000])
    }
    
    func listenToRoomUpdates(roomId: String) -> AnyPublisher<Room, Error> {
        let subject = PassthroughSubject<Room, Error>()
        let listener = roomsCollection.document(roomId).addSnapshotListener { documentSnapshot, error in
            guard let document = documentSnapshot else {
                if let error = error { subject.send(completion: .failure(error)) }
                return
            }
            do {
                let room = try document.data(as: Room.self)
                subject.send(room)
            } catch { subject.send(completion: .failure(error)) }
        }
        return subject.handleEvents(receiveCancel: { listener.remove() }).eraseToAnyPublisher()
    }
    
    func addDrinkForUser(userId: String, drinkId: String, in room: Room) async throws {
        guard let roomId = room.id else { return }
        let roomRef = roomsCollection.document(roomId)
        let scoreFieldPath = "scores.\(userId).\(drinkId)"
        try await roomRef.setData(["scores": [userId: [drinkId: FieldValue.increment(Int64(1))]]], merge: true)
    }

    func updateRoomPhotoURL(roomId: String, url: String) async throws {
        try await roomsCollection.document(roomId).updateData(["photoURL": url])
    }
    
    func leaveRoom(_ room: Room, userId: String) async throws {
        guard let roomId = room.id else { throw URLError(.badURL) }
        
        try await roomsCollection.document(roomId).updateData([
            "memberIds": FieldValue.arrayRemove([userId]),
            "scores.\(userId)": FieldValue.delete(),
            "userCredits.\(userId)": FieldValue.delete()
        ])
    }
    
    func updateDrinks(forRoomId roomId: String, with newDrinks: [Drink]) async throws {
        let drinksData = try newDrinks.map { try Firestore.Encoder().encode($0) }
        
        try await roomsCollection.document(roomId).updateData([
            "drinks": drinksData
        ])
    }

    private func generateInvitationCode(length: Int = 6) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
}
