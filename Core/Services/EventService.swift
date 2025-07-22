//
//  EventService.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import Foundation
import FirebaseFirestore
import Combine

class EventService {
    static let shared = EventService()
    private let db = Firestore.firestore()

    private init() {}

    func createEvent(event: Event, inRoomId roomId: String) async throws -> String {
        do {
            // Create event in the subcollection of the room
            let documentRef = db.collection("rooms").document(roomId).collection("events").document()
            var eventWithId = event
            eventWithId.id = documentRef.documentID
            
            try documentRef.setData(from: eventWithId)
            print("Event created with ID: \(documentRef.documentID) in room \(roomId)")
            return documentRef.documentID
        } catch {
            print("Error creating event in room \(roomId): \(error.localizedDescription)")
            throw error
        }
    }

    func fetchEvent(id: String, inRoomId roomId: String) async throws -> Event {
        do {
            let document = try await db.collection("rooms").document(roomId).collection("events").document(id).getDocument()
            let event = try document.data(as: Event.self)
            return event
        } catch {
            print("Error fetching event \(id) from room \(roomId): \(error.localizedDescription)")
            throw error
        }
    }
    
    func eventsPublisher(forRoomId roomId: String) -> AnyPublisher<[Event], Error> {
        let subject = PassthroughSubject<[Event], Error>()
        
        let listener = db.collection("rooms").document(roomId).collection("events")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    subject.send([])
                    return
                }
                
                let events = documents.compactMap { try? $0.data(as: Event.self) }
                subject.send(events)
            }
        
        // TODO: Manage listener lifecycle to remove it when no longer needed.
        // For now, it will be active as long as the app runs.
        
        return subject.eraseToAnyPublisher()
    }

    func addDrinkToEvent(eventId: String, inRoomId roomId: String, userId: String, drinkId: String) async throws {
        let eventRef = db.collection("rooms").document(roomId).collection("events").document(eventId)
        let newDrinkEntry = EventDrinkEntry(userId: userId, drinkId: drinkId, timestamp: Date())

        do {
            let drinkData = try newDrinkEntry.asDictionary()
            try await eventRef.updateData([
                "drinksConsumed": FieldValue.arrayUnion([drinkData])
            ])
            print("Drink \(drinkId) added for user \(userId) to event \(eventId) in room \(roomId)")
        } catch {
            print("Error adding drink to event \(eventId) in room \(roomId): \(error.localizedDescription)")
            throw error
        }
    }

    func findActiveEvent(forRoomId roomId: String) async throws -> Event? {
        let now = Date()
        let query = db.collection("rooms").document(roomId).collection("events")
            .whereField("startDate", isLessThanOrEqualTo: now)
            .whereField("endDate", isGreaterThanOrEqualTo: now)
            .limit(to: 1)

        let snapshot = try await query.getDocuments()
        return try snapshot.documents.first?.data(as: Event.self)
    }
}