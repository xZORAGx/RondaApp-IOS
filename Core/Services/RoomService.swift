// Fichero: RondaApp/Core/Services/RoomService.swift

import Foundation
import Firebase
import FirebaseFirestore
import Combine
import CoreLocation // ✅ ESTA ES LA LÍNEA QUE AÑADIMOS

class RoomService {
    
    static let shared = RoomService()
    private let db = Firestore.firestore()
    
    private var roomsCollection: CollectionReference {
        return db.collection("rooms")
    }
    
    private var checkInsCollection: CollectionReference { db.collection("checkIns") }
    
    
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
            
            let expirationDate = Date().addingTimeInterval(24 * 60 * 60)
            let expirationTimestamp = Timestamp(date: expirationDate)
            
            transaction.updateData([
                "status": newStatus.rawValue,
                "resolvedAt": expirationTimestamp
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

        // 1. Actualizar la puntuación en la sala general
        try await roomRef.setData(["scores": [userId: [drinkId: FieldValue.increment(Int64(1))]]], merge: true)

        // 2. Verificar y actualizar eventos activos
        if let activeEvent = try? await EventService.shared.findActiveEvent(forRoomId: roomId) {
            try await EventService.shared.addDrinkToEvent(eventId: activeEvent.id!, inRoomId: roomId, userId: userId, drinkId: drinkId)
        }
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
    
    // --- LÓGICA DE DUELOS ---
    
    func listenToDuels(inRoomId roomId: String) -> AnyPublisher<[Duel], Error> {
        let subject = PassthroughSubject<[Duel], Error>()
        
        let listener = roomsCollection.document(roomId).collection("duels")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    if let error = error { subject.send(completion: .failure(error)) }
                    return
                }
                
                let duels = documents.compactMap { try? $0.data(as: Duel.self) }
                subject.send(duels)
            }
        
        return subject.handleEvents(receiveCancel: { listener.remove() }).eraseToAnyPublisher()
    }
    
    func createDuel(_ duel: Duel, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let newDuelRef = roomRef.collection("duels").document()
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let roomDocument: DocumentSnapshot
            do { try roomDocument = transaction.getDocument(roomRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }
            
            guard let room = try? roomDocument.data(as: Room.self) else { return nil }
            
            guard let challengerCredits = room.userCredits[duel.challengerId], challengerCredits >= duel.wager else {
                errorPointer?.pointee = NSError(domain: "AppError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No tienes suficientes créditos para lanzar este reto."])
                return nil
            }
            
            transaction.updateData(["userCredits.\(duel.challengerId)": challengerCredits - duel.wager], forDocument: roomRef)
            
            do {
                try transaction.setData(from: duel, forDocument: newDuelRef)
            } catch let setDataError as NSError {
                errorPointer?.pointee = setDataError
                return nil
            }
            return nil
        }
    }
    
    // ✅ NUEVA FUNCIÓN: Aceptar un duelo.
    func acceptDuel(duel: Duel, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let duelRef = roomRef.collection("duels").document(duel.id!)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let roomDocument: DocumentSnapshot
            do { try roomDocument = transaction.getDocument(roomRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }
            
            guard let room = try? roomDocument.data(as: Room.self) else { return nil }
            
            guard let opponentCredits = room.userCredits[duel.opponentId], opponentCredits >= duel.wager else {
                errorPointer?.pointee = NSError(domain: "AppError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No tienes suficientes créditos para aceptar este duelo."])
                return nil
            }
            
            // Descontar créditos al oponente y actualizar estado del duelo
            transaction.updateData(["userCredits.\(duel.opponentId)": opponentCredits - duel.wager], forDocument: roomRef)
            transaction.updateData(["status": DuelStatus.inProgress.rawValue], forDocument: duelRef)
            
            return nil
        }
    }
    
    // ✅ NUEVA FUNCIÓN: Rechazar un duelo.
    func declineDuel(duel: Duel, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let duelRef = roomRef.collection("duels").document(duel.id!)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            // Devolver los créditos al retador
            transaction.updateData(["userCredits.\(duel.challengerId)": FieldValue.increment(Int64(duel.wager))], forDocument: roomRef)
            // Borrar el documento del duelo
            transaction.deleteDocument(duelRef)
            return nil
        }
    }
    
    
    func resolveDuel(duel: Duel, winnerId: String?, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let duelRef = roomRef.collection("duels").document(duel.id!)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let wager = duel.wager
            if let winnerId = winnerId {
                transaction.updateData(["userCredits.\(winnerId)": FieldValue.increment(Int64(wager * 2))], forDocument: roomRef)
            } else {
                transaction.updateData([
                    "userCredits.\(duel.challengerId)": FieldValue.increment(Int64(wager)),
                    "userCredits.\(duel.opponentId)": FieldValue.increment(Int64(wager))
                ], forDocument: roomRef)
            }
            
            let expirationDate = Date().addingTimeInterval(24 * 60 * 60)
            transaction.updateData([
                "status": DuelStatus.resolved.rawValue,
                "winnerId": winnerId ?? "draw",
                "resolvedAt": Timestamp(date: expirationDate)
            ], forDocument: duelRef)
            
            return nil
        }
        
        try await postDuelResultToChat(duel: duel, winnerId: winnerId, inRoomId: roomId)
    }
    
    private func postDuelResultToChat(duel: Duel, winnerId: String?, inRoomId roomId: String) async throws {
        var messageText = ""
        let challengerName = (try? await UserService.shared.fetchUser(withId: duel.challengerId))?.username ?? "Jugador 1"
        let opponentName = (try? await UserService.shared.fetchUser(withId: duel.opponentId))?.username ?? "Jugador 2"
        
        if let winnerId = winnerId {
            let winnerName = (winnerId == duel.challengerId) ? challengerName : opponentName
            messageText = "¡Duelo finalizado! 🔥\n'\(duel.title)'\nGanador: \(winnerName)\nPremio: \(duel.wager * 2) créditos."
        } else {
            messageText = "¡Duelo finalizado en empate! 🤝\n'\(duel.title)'\nSe han devuelto \(duel.wager) créditos a \(challengerName) y a \(opponentName)."
        }
        
        // ✅ CORRECCIÓN: Usamos 'textContent' y definimos el 'mediaType'.
        let chatMessage: [String: Any] = [
            "textContent": messageText,
            "authorId": "system",
            "timestamp": FieldValue.serverTimestamp(),
            "mediaType": "text"
        ]
        
        try await roomsCollection.document(roomId).collection("messages").addDocument(data: chatMessage)
    }
    func initiateDuelPoll(for duel: Duel, inRoomId roomId: String) async throws {
        guard let duelId = duel.id else { throw URLError(.badURL) }
        
        let roomRef = roomsCollection.document(roomId)
        let duelRef = roomRef.collection("duels").document(duelId)
        let newPollRef = roomRef.collection("polls").document()
        let newChatMessageRef = roomRef.collection("messages").document()
        
        let challengerName = (try? await UserService.shared.fetchUser(withId: duel.challengerId))?.username ?? "Retador"
        let opponentName = (try? await UserService.shared.fetchUser(withId: duel.opponentId))?.username ?? "Oponente"
        
        let expirationDate = Date().addingTimeInterval(24 * 60 * 60)
        let newPoll = Poll(
            id: newPollRef.documentID,
            duelId: duelId,
            question: "¿Quién ganó el duelo: \(challengerName) vs \(opponentName)?",
            votes: [duel.challengerId: [], duel.opponentId: [], "draw": []],
            memberCountAtCreation: (try await roomRef.getDocument().data()?["memberIds"] as? [String])?.count ?? 0,
            expiresAt: Timestamp(date: expirationDate)
        )
        
        let chatMessage: [String: Any] = [
            "authorId": "system",
            "text": "¡Nueva encuesta para resolver un duelo!",
            "pollId": newPoll.id,
            "duelId": duel.id, // <-- LÍNEA AÑADIDA
            "timestamp": FieldValue.serverTimestamp(),
            "mediaType": "poll"
        ]
        
        let batch = db.batch()
        
        try batch.setData(from: newPoll, forDocument: newPollRef)
        batch.setData(chatMessage, forDocument: newChatMessageRef)
        batch.updateData(["status": DuelStatus.inPoll.rawValue, "pollId": newPoll.id], forDocument: duelRef)
        
        try await batch.commit()
    }
    
    // ✅ NUEVA: Escucha los cambios en la subcolección de encuestas
    func listenToPolls(inRoomId roomId: String) -> AnyPublisher<[Poll], Error> {
        let subject = PassthroughSubject<[Poll], Error>()
        let listener = roomsCollection.document(roomId).collection("polls")
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    if let error = error { subject.send(completion: .failure(error)) }
                    return
                }
                let polls = documents.compactMap { try? $0.data(as: Poll.self) }
                subject.send(polls)
            }
        return subject.handleEvents(receiveCancel: { listener.remove() }).eraseToAnyPublisher()
    }
    
    // ✅ NUEVA: Registra un voto y resuelve el duelo si hay mayoría
    func castVote(poll: Poll, duel: Duel, option: String, userId: String, inRoomId roomId: String) async throws {
        let roomRef = roomsCollection.document(roomId)
        let pollRef = roomRef.collection("polls").document(poll.id!)
        let duelRef = roomRef.collection("duels").document(duel.id!)
        
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let pollDocument: DocumentSnapshot
            do { try pollDocument = transaction.getDocument(pollRef) }
            catch let error as NSError { errorPointer?.pointee = error; return nil }
            
            guard var currentPoll = try? pollDocument.data(as: Poll.self) else { return nil }
            
            let allVoters = currentPoll.votes.values.flatMap { $0 }
            guard !allVoters.contains(userId) else { return nil }
            
            currentPoll.votes[option, default: []].append(userId)
            transaction.updateData(["votes": currentPoll.votes], forDocument: pollRef)
            
            let majorityCount = (currentPoll.memberCountAtCreation / 2) + 1
            if let voteCount = currentPoll.votes[option]?.count, voteCount >= majorityCount {
                var creditChanges: [String: Any] = [:]
                let winnerId = (option == "draw") ? nil : option
                
                if let winnerId = winnerId {
                    creditChanges["userCredits.\(winnerId)"] = FieldValue.increment(Int64(duel.wager * 2))
                } else {
                    creditChanges["userCredits.\(duel.challengerId)"] = FieldValue.increment(Int64(duel.wager))
                    creditChanges["userCredits.\(duel.opponentId)"] = FieldValue.increment(Int64(duel.wager))
                }
                
                if !creditChanges.isEmpty {
                    transaction.updateData(creditChanges, forDocument: roomRef)
                }
                
                let expirationDate = Date().addingTimeInterval(24 * 60 * 60)
                transaction.updateData([
                    "status": DuelStatus.resolved.rawValue,
                    "winnerId": winnerId ?? "draw",
                    "resolvedAt": Timestamp(date: expirationDate)
                ], forDocument: duelRef)
                
                transaction.deleteDocument(pollRef)
            }
            return nil
        }
        try await postPollVoteToChat(poll: poll, voterId: userId, option: option, inRoomId: roomId)
    }
    
    // ✅ NUEVA FUNCIÓN AUXILIAR: Crea un mensaje en el chat para notificar un voto.
    private func postPollVoteToChat(poll: Poll, voterId: String, option: String, inRoomId roomId: String) async throws {
        let voterName = (try? await UserService.shared.fetchUser(withId: voterId))?.username ?? "Alguien"
        let optionName: String
        
        if option == "draw" {
            optionName = "Empate"
        } else {
            optionName = (try? await UserService.shared.fetchUser(withId: option))?.username ?? "un jugador"
        }
        
        let messageText = "\(voterName) ha votado por \(optionName)."
        
        // ✅ CORRECCIÓN: Usamos 'textContent' y definimos el 'mediaType'.
        let chatMessage: [String: Any] = [
            "textContent": messageText,
            "authorId": "system",
            "timestamp": FieldValue.serverTimestamp(),
            "mediaType": "text"
        ]
        
        try await roomsCollection.document(roomId).collection("messages").addDocument(data: chatMessage)
    }
    
    func listenToCheckIns(inRoomId roomId: String) -> AnyPublisher<[CheckIn], Error> {
        let subject = PassthroughSubject<[CheckIn], Error>()
        
        let oneWeekAgo = Date().addingTimeInterval(-7 * 24 * 60 * 60)
        
        // 1. Apuntamos directamente a la subcolección del room específico.
        let listener = roomsCollection.document(roomId).collection("checkIns")
            .whereField("timestamp", isGreaterThan: oneWeekAgo)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                guard let documents = querySnapshot?.documents else { return }
                
                let checkIns = documents.compactMap { try? $0.data(as: CheckIn.self) }
                subject.send(checkIns)
            }
        
        return subject.handleEvents(receiveCancel: { listener.remove() }).eraseToAnyPublisher()
    }
    
    // ✅ FUNCIÓN ACTUALIZADA: Ahora escribe en la subcolección
    func createCheckIn(
        for user: User,
        inRoomId roomId: String,
        drinkId: String,
        caption: String?,
        imageData: Data?,
        location: CLLocation?
    ) async throws {
        // 1. Preparamos todas las referencias y datos necesarios.
        let newCheckInRef = roomsCollection.document(roomId).collection("checkIns").document()
        let checkInId = newCheckInRef.documentID
        let roomRef = roomsCollection.document(roomId)
        let messagesRef = roomRef.collection("messages").document()
        
        // 2. Subimos la imagen a Storage PRIMERO.
        var photoURL: String?
        if let data = imageData {
            photoURL = try await StorageService.shared.uploadCheckInImage(
                data: data,
                roomId: roomId,
                checkInId: checkInId
            ).absoluteString
        }
        
        // 3. Construimos el objeto CheckIn final.
        let geoPoint = location.map { GeoPoint(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
        let newCheckIn = CheckIn(
            userId: user.uid, roomId: roomId, drinkId: drinkId,
            photoURL: photoURL, caption: caption, location: geoPoint
        )
        
        // 4. Creamos el objeto Message si es necesario.
        let shouldCreateMessage = photoURL != nil || (caption != nil && !caption!.isEmpty)
        let newMessage = Message(
            authorId: user.uid, timestamp: newCheckIn.timestamp, mediaType: .checkIn, checkInId: checkInId
        )
        
        // 5. Buscamos el evento activo ANTES de la transacción.
        let activeEvent = try? await EventService.shared.findActiveEvent(forRoomId: roomId)

        // 6. Ejecutamos la transacción.
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let scoreFieldPath = "scores.\(user.uid).\(drinkId)"
            
            // Operación 1: Actualizar la puntuación de la sala.
            transaction.updateData([scoreFieldPath: FieldValue.increment(Int64(1))], forDocument: roomRef)
            
            // Operación 2: Guardar el nuevo CheckIn.
            do {
                try transaction.setData(from: newCheckIn, forDocument: newCheckInRef)
            } catch { errorPointer?.pointee = error as NSError; return nil }
            
            // Operación 3: Guardar el mensaje del chat si es necesario.
            if shouldCreateMessage {
                do {
                    try transaction.setData(from: newMessage, forDocument: messagesRef)
                } catch { errorPointer?.pointee = error as NSError; return nil }
            }

            // Operación 4: Si hay un evento activo, añadir la bebida.
            if let event = activeEvent, let eventId = event.id {
                let eventRef = self.db.collection("rooms").document(roomId).collection("events").document(eventId)
                let newDrinkEntry = EventDrinkEntry(userId: user.uid, drinkId: drinkId, timestamp: Date())
                do {
                    let drinkData = try newDrinkEntry.asDictionary()
                    transaction.updateData(["drinksConsumed": FieldValue.arrayUnion([drinkData])], forDocument: eventRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            
            return nil
        }
    }
  }

