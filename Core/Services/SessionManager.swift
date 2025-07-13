//
//  SessionManager.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 11/7/25.
//

//  RondaApp/Core/Services/SessionManager.swift

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine

// Definimos los posibles estados de la sesión del usuario
enum SessionState {
    case loggedOut
    case needsPolicyAcceptance(firebaseUser: FirebaseAuth.User)
    case needsProfileCreation(user: User)
    case loggedIn(user: User)
}

class SessionManager: ObservableObject {
    
    @Published var sessionState: SessionState = .loggedOut
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()
    
    init() {
        // Escuchamos continuamente los cambios de estado de Firebase Authentication
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            
            if let firebaseUser = user {
                self.checkUserStatus(firebaseUser: firebaseUser)
            } else {
                self.sessionState = .loggedOut
            }
        }
    }
    
    private func checkUserStatus(firebaseUser: FirebaseAuth.User) {
        let userRef = db.collection("users").document(firebaseUser.uid)
        
        userRef.getDocument { document, error in
            if let document = document, document.exists {
                // El usuario ya existe en nuestra base de datos.
                do {
                    let rondaUser = try document.data(as: User.self)
                    
                    if !rondaUser.hasAcceptedPolicy {
                        self.sessionState = .needsPolicyAcceptance(firebaseUser: firebaseUser)
                    } else if !rondaUser.hasCompletedProfile {
                        self.sessionState = .needsProfileCreation(user: rondaUser)
                    } else {
                        self.sessionState = .loggedIn(user: rondaUser)
                    }
                    
                } catch {
                    print("Error al decodificar el usuario: \(error)")
                    self.sessionState = .needsPolicyAcceptance(firebaseUser: firebaseUser)
                }
            } else {
                // Es un usuario completamente nuevo, no existe en nuestra DB.
                self.sessionState = .needsPolicyAcceptance(firebaseUser: firebaseUser)
            }
        }
    }
    
    func acceptPolicy(firebaseUser: FirebaseAuth.User) {
        let partialUser = User(uid: firebaseUser.uid, email: firebaseUser.email, hasAcceptedPolicy: true, hasCompletedProfile: false)
        
        do {
            try db.collection("users").document(partialUser.uid).setData(from: partialUser, merge: true)
            self.sessionState = .needsProfileCreation(user: partialUser)
        } catch {
            print("Error al aceptar la política: \(error)")
        }
    }
    
    func completeProfile(user: User, username: String, age: Int) {
        var updatedUser = user
        updatedUser.username = username
        updatedUser.age = age
        updatedUser.hasCompletedProfile = true
        
        do {
            try db.collection("users").document(updatedUser.uid).setData(from: updatedUser, merge: true)
            self.sessionState = .loggedIn(user: updatedUser)
        } catch {
            print("Error al completar el perfil: \(error)")
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            // El listener de Auth se encargará de cambiar el estado a .loggedOut automáticamente.
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
        }
    }
}
