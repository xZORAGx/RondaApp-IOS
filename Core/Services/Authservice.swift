//  RondaApp/Core/Services/AuthService.swift

import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices // Necesario para la futura implementación de Apple Sign In
import CryptoKit             // Necesario para la futura implementación de Apple Sign In

class AuthService {
    
    static let shared = AuthService()
    private let auth = Auth.auth()
    
    private init() {}
    
    // MARK: - Sign In with Google
    @MainActor
    func signInWithGoogle() async throws -> AuthDataResult {
        guard let topVC = await topViewController() else {
            throw URLError(.cannotFindHost)
        }
        
        let gidSignInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: topVC)
        
        guard let idToken = gidSignInResult.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }
        
        let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: gidSignInResult.user.accessToken.tokenString)
        
        return try await auth.signIn(with: credential)
    }
    
    // MARK: - Sign In with Apple (Pospuesto)
    
    func signInWithApple() {
        // Esta función está vacía intencionadamente para evitar errores de compilación.
        // El botón en la LoginView debe estar deshabilitado para que no se pueda llamar.
        print("Intento de usar Sign in with Apple (actualmente deshabilitado).")
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        // Cerramos sesión tanto en Google como en Firebase para un logout completo.
        if GIDSignIn.sharedInstance.currentUser != nil {
            GIDSignIn.sharedInstance.signOut()
        }
        try auth.signOut()
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return nil
        }
        
        var topController = rootViewController
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}


