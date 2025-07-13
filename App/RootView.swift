// Fichero: RondaApp/App/RootView.swift

import SwiftUI

struct RootView: View {
    
    @StateObject private var sessionManager = SessionManager()
    
    var body: some View {
        switch sessionManager.sessionState {
            
        case .checking:
            ProgressView()
                .controlSize(.large)
            
        case .loggedOut:
            LoginView(sessionManager: sessionManager)
            
        case .needsPolicyAcceptance(let firebaseUser):
            PrivacyPolicyView {
                sessionManager.acceptPolicy(firebaseUser: firebaseUser)
            }
            
        case .needsProfileCreation(let user):
            CreateProfileView(user: user) { username, age, imageData in
                sessionManager.completeProfile(
                    user: user,
                    username: username,
                    age: age,
                    imageData: imageData
                )
            }
            
        case .loggedIn(let user):
            RoomListView(user: user, sessionManager: sessionManager)
        }
    }
}

#Preview {
    RootView()
}
