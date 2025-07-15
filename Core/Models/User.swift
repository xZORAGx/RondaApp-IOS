//
//  User.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 11/7/25.
//

//  RondaApp/Core/Models/User.swift

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable, Equatable {
    @DocumentID var id: String?
    
    let uid: String
    let email: String?
    var photoURL: String?
    
    // Campos que el usuario rellenará
    var username: String?
    var age: Int?
    
    // Campos de estado interno
    var hasAcceptedPolicy: Bool = false
    var hasCompletedProfile: Bool = false // <-- Nuevo campo clave
}
