//
//  ChatService.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 15/7/25.
//

// Fichero: RondaApp/Core/Services/ChatService.swift

import Foundation
import Firebase
import Combine

class ChatService {
    static let shared = ChatService()
    private let db = Firestore.firestore()
    
    private func messagesCollection(forRoomId roomId: String) -> CollectionReference {
        return db.collection("rooms").document(roomId).collection("messages")
    }
    
    /// Escucha los nuevos mensajes de una sala en tiempo real.
    func listenForMessages(roomId: String) -> AnyPublisher<[Message], Error> {
        let subject = PassthroughSubject<[Message], Error>()
        
        let listener = messagesCollection(forRoomId: roomId)
            .order(by: "timestamp", descending: false) // Ordenamos por fecha
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    subject.send(completion: .failure(error))
                    return
                }
                
                guard let documents = snapshot?.documents else { return }
                
                let messages = documents.compactMap { try? $0.data(as: Message.self) }
                subject.send(messages)
            }
        
        return subject.handleEvents(receiveCancel: {
            listener.remove()
        }).eraseToAnyPublisher()
    }
    
    /// Envía un mensaje (de texto o multimedia) a una sala.
    func sendMessage(_ message: Message, inRoomId roomId: String) async throws {
        // Simplemente añadimos el documento a la subcolección de mensajes.
        try messagesCollection(forRoomId: roomId).addDocument(from: message)
    }
}
