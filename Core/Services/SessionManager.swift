// Fichero: RondaApp/Core/Managers/SessionManager.swift

import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices // ✅ Añadido
import CryptoKit            // ✅ Añadido

@MainActor
class SessionManager: ObservableObject {
    
    // El enum que define los posibles estados de la sesión
    enum SessionState {
        case checking
        case loggedOut
        case needsPolicyAcceptance(firebaseUser: FirebaseAuth.User)
        case needsProfileCreation(user: User)
        case loggedIn(user: User)
    }
    
    // --- Propiedades Publicadas (Published) ---
    @Published var sessionState: SessionState = .checking
    
    // Propiedades para gestionar el estado de la UI durante el login
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // --- Propiedades Privadas ---
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private let userService = UserService.shared
    private let authService = AuthService.shared
    private var currentNonce: String? // ✅ Añadido para Apple Sign In

    init() {
        listenToAuthState()
    }
    
    deinit {
        if let handle = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // --- Lógica Principal de Estado ---
    
    func listenToAuthState() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, firebaseUser in
            Task {
                await self?.handleUserChange(firebaseUser: firebaseUser)
            }
        }
    }
    
    // Fichero: RoomService.swift (Añade esta función dentro de la clase)


    
    private func handleUserChange(firebaseUser: FirebaseAuth.User?) async {
        guard let firebaseUser = firebaseUser else {
            self.sessionState = .loggedOut
            return
        }
        
        do {
            let appUser = try await userService.fetchUser(withId: firebaseUser.uid)
            
            if !appUser.hasAcceptedPolicy {
                self.sessionState = .needsPolicyAcceptance(firebaseUser: firebaseUser)
            } else if !appUser.hasCompletedProfile {
                self.sessionState = .needsProfileCreation(user: appUser)
            } else {
                self.sessionState = .loggedIn(user: appUser)
            }
        } catch {
            print("Usuario no encontrado en Firestore (UID: \(firebaseUser.uid)). Se considera un nuevo usuario.")
            self.sessionState = .needsPolicyAcceptance(firebaseUser: firebaseUser)
        }
    }
    
    // --- Acciones de Autenticación ---
    
    func signInWithGoogle() {
        self.isLoading = true
        self.errorMessage = nil
        
        Task {
            do {
                let _ = try await authService.signInWithGoogle()
            } catch {
                self.errorMessage = "Error con Google Sign In: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }

    // ✅ --- FUNCIONES NUEVAS PARA APPLE SIGN IN ---
    
    func handleAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        self.isLoading = true
        self.errorMessage = nil
        
        Task {
            do {
                guard let nonce = currentNonce else {
                    fatalError("Nonce inválido. No se puede proceder con la autenticación.")
                }
                let _ = try await authService.signInWithApple(result: result, nonce: nonce)
                
            } catch is CancellationError {
                // Si es un error de cancelación por parte del usuario, no mostramos alerta.
                print("Inicio de sesión con Apple cancelado por el usuario.")
            } catch {
                self.errorMessage = "Error con Apple Sign In: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    // --- Lógica de Onboarding ---

    func acceptPolicy(firebaseUser: FirebaseAuth.User) {
        Task {
            self.isLoading = true
            self.errorMessage = nil
            
            do {
                let partialUser = User(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email,
                    hasAcceptedPolicy: true,
                    hasCompletedProfile: false
                )
                try await UserService.shared.createInitialUser(user: partialUser)
                await handleUserChange(firebaseUser: firebaseUser)
                
            } catch {
                let errorMessageText = "No se pudo guardar la aceptación de la política. Por favor, inténtalo de nuevo. Error: \(error.localizedDescription)"
                print(errorMessageText)
                self.errorMessage = errorMessageText
            }
            
            self.isLoading = false
        }
    }
    
    func completeProfile(user: User, username: String, age: String, imageData: Data?) {
        Task {
            self.isLoading = true
            self.errorMessage = nil
            
            guard let ageInt = Int(age) else {
                self.errorMessage = "La edad debe ser un número válido."
                self.isLoading = false
                return
            }
            
            guard let firebaseUser = Auth.auth().currentUser else {
                self.errorMessage = "No se ha encontrado un usuario activo. Por favor, reinicia la aplicación."
                self.isLoading = false
                return
            }
            
            do {
                try await UserService.shared.updateUserProfile(
                    userId: user.uid,
                    username: username,
                    age: ageInt,
                    imageData: imageData
                )
                await handleUserChange(firebaseUser: firebaseUser)
                
            } catch {
                let errorMessageText = "No se pudo guardar tu perfil. Por favor, inténtalo de nuevo. Error: \(error.localizedDescription)"
                print(errorMessageText)
                self.errorMessage = errorMessageText
            }
            self.isLoading = false
        }
    }
    
    // ✅ --- HELPERS CRIPTOGRÁFICOS PARA APPLE SIGN IN ---

    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("No se pudo generar un byte aleatorio seguro. \(errorCode)")
                }
                return random
            }
            for random in randoms {
                if remainingLength == 0 {
                    break
                }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        return hashString
    }
}
