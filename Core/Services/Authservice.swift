// Fichero: RondaApp/Core/Services/AuthService.swift

import Foundation
import FirebaseAuth
import GoogleSignIn
import GoogleSignInSwift
import AuthenticationServices
import CryptoKit

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
    
    // MARK: - Sign In with Apple (Implementación Completa)
    @MainActor
    func signInWithApple(result: Result<ASAuthorization, Error>, nonce: String) async throws -> AuthDataResult {
        switch result {
        case .success(let authorization):
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                throw NSError(domain: "AppleAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener la credencial de Apple."])
            }
            
            guard let appleIDToken = appleIDCredential.identityToken else {
                throw NSError(domain: "AppleAuthError", code: 2, userInfo: [NSLocalizedDescriptionKey: "No se pudo obtener el ID Token de Apple."])
            }
            
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                throw NSError(domain: "AppleAuthError", code: 3, userInfo: [NSLocalizedDescriptionKey: "No se pudo convertir el token a String."])
            }

            // Crear la credencial de Firebase para Apple
            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // Iniciar sesión en Firebase
            return try await auth.signIn(with: firebaseCredential)
            
        case .failure(let error):
            // Si el usuario cancela, no es un error fatal.
            if (error as? ASAuthorizationError)?.code == .canceled {
                // Lanzamos un error especial para que el SessionManager lo identifique
                // y no muestre una alerta de error innecesaria.
                throw CancellationError()
            }
            // Si es otro tipo de error, sí lo lanzamos.
            throw error
        }
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
