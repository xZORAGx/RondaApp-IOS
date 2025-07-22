// Fichero: RondaApp/Core/Services/UserService.swift

import Foundation
import FirebaseFirestore

class UserService {
    
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    private var usersCollection: CollectionReference {
        return db.collection("users")
    }
    
    // --- FUNCIONES QUE YA TENÍAS ---
    
    /// Obtiene los documentos de múltiples usuarios a partir de una lista de IDs.
    func fetchUsers(withIDs uids: [String]) async throws -> [User] {
        guard !uids.isEmpty else { return [] }
        let snapshot = try await usersCollection.whereField("uid", in: uids).getDocuments()
        let users = snapshot.documents.compactMap { try? $0.data(as: User.self) }
        return users
    }
    
    func updateUserProfile(userId: String, username: String, age: Int, imageData: Data?) async throws {
        var photoURL: String? = nil
        if let data = imageData {
            let url = try await StorageService.shared.uploadProfileImage(imageData: data, userId: userId)
            photoURL = url.absoluteString
        }
        
        var userData: [String: Any] = [
            "username": username,
            "age": age,
            "hasCompletedProfile": true
        ]
        
        if let photoURL = photoURL {
            userData["photoURL"] = photoURL
        }
        
        try await usersCollection.document(userId).setData(userData, merge: true)
    }
    
    func userExists(withId uid: String) async -> Bool {
        do {
            return try await usersCollection.document(uid).getDocument().exists
        } catch {
            return false
        }
    }
    
    // --- ✅ FUNCIONES NUEVAS AÑADIDAS ---

    /// 1. Obtiene el perfil completo de un único usuario a partir de su ID.
    ///    El SessionManager la necesita para cargar el perfil del usuario que ha iniciado sesión.
    func fetchUser(withId uid: String) async throws -> User {
        // Usamos getDocument(as:) para decodificar el documento directamente a nuestro modelo User.
        return try await usersCollection.document(uid).getDocument(as: User.self)
    }
    
    /// 2. Crea el documento inicial para un usuario nuevo después de aceptar las políticas.
    ///    El SessionManager la necesita en la función `acceptPolicy`.
    func createInitialUser(user: User) async throws {
        // Usamos el UID del usuario como ID del documento y guardamos el objeto completo.
        try usersCollection.document(user.uid).setData(from: user, merge: true)
    }

    /// Obtiene todos los usuarios de la base de datos.
    func fetchAllUsers() async throws -> [User] {
        let snapshot = try await usersCollection.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: User.self) }
    }
}
