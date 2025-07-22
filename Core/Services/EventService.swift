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
            // ▼▼▼ CAMBIO CLAVE AQUÍ ▼▼▼
            // 1. Usamos el codificador de Firestore para convertir el objeto a un diccionario.
            // Esto se asegurará de que el 'Date' se convierta en un 'Timestamp'.
            let drinkData = try Firestore.Encoder().encode(newDrinkEntry)
            
            // 2. Usamos arrayUnion con el diccionario ya codificado correctamente.
            try await eventRef.updateData([
                "drinksConsumed": FieldValue.arrayUnion([drinkData])
            ])
            print("Bebida \(drinkId) añadida para el usuario \(userId) al evento \(eventId) en la sala \(roomId)")
        } catch {
            print("Error al añadir la bebida al evento \(eventId) en la sala \(roomId): \(error.localizedDescription)")
            throw error
        }
    }

    // Fichero: EventService.swift (Versión corregida)

    func findActiveEvent(forRoomId roomId: String) async throws -> Event? {
        let now = Date()
        
        // 1. Hacemos una consulta a Firestore con UN SOLO filtro de rango.
        // Pedimos todos los eventos que ya han comenzado y que aún no han terminado.
        // Ordenamos por fecha de inicio para coger el más reciente si hubiera varios.
        let query = db.collection("rooms").document(roomId).collection("events")
            .whereField("startDate", isLessThanOrEqualTo: now)
            .order(by: "startDate", descending: true)

        let snapshot = try await query.getDocuments()
        
        // 2. Decodificamos todos los eventos que cumplen el primer filtro.
        let possibleEvents = snapshot.documents.compactMap { try? $0.data(as: Event.self) }
        
        // 3. Filtramos en el CÓDIGO para aplicar la segunda condición.
        // Usamos la propiedad `isActive` que ya tienes en tu modelo `Event`.
        let activeEvent = possibleEvents.first { event in
            // El `event.isActive` comprueba si "now" está entre startDate y endDate.
            // Esto es más eficiente que comprobar solo la endDate.
            return event.isActive
        }
        
        // 4. Devolvemos el evento que cumple AMBAS condiciones.
        return activeEvent
    }
}
