//
//  RootView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 11/7/25.
//

//  RondaApp/App/RootView.swift


import SwiftUI

struct RootView: View {
    
    @StateObject private var sessionManager = SessionManager()
    
    var body: some View {
        switch sessionManager.sessionState {
        case .loggedOut:
            LoginView()
        
        case .needsPolicyAcceptance(let firebaseUser):
            PrivacyPolicyView {
                sessionManager.acceptPolicy(firebaseUser: firebaseUser)
            }
            
        case .needsProfileCreation(let user):
            CreateProfileView(user: user) { username, age in
                sessionManager.completeProfile(user: user, username: username, age: age)
            }
            
        case .loggedIn(let user):
            // Reemplazamos MainAppView por nuestra nueva pantalla principal
            RoomListView(user: user, sessionManager: sessionManager)
        }
    }
}
