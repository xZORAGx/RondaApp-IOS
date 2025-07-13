// Fichero: RondaApp/Core/Managers/SessionManager.swift

import Foundation
import FirebaseAuth
import Combine

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
    
    private func handleUserChange(firebaseUser: FirebaseAuth.User?) async {
        guard let firebaseUser = firebaseUser else {
            self.sessionState = .loggedOut
            return
        }
        
        // Intentamos cargar el usuario desde Firestore
        do {
            let appUser = try await userService.fetchUser(withId: firebaseUser.uid)
            
            // Si el usuario existe, comprobamos su estado de onboarding
            if !appUser.hasAcceptedPolicy {
                // No ha aceptado la política -> necesita aceptar la política
                self.sessionState = .needsPolicyAcceptance(firebaseUser: firebaseUser)
            } else if !appUser.hasCompletedProfile {
                // Aceptó la política pero no ha completado el perfil -> necesita crear el perfil
                self.sessionState = .needsProfileCreation(user: appUser)
            } else {
                // Ha completado todo -> está logueado
                self.sessionState = .loggedIn(user: appUser)
            }
        } catch {
            // Si hay un error al cargar (probablemente porque no existe), es un NUEVO USUARIO.
            // Lo llevamos al primer paso: aceptar la política.
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
    
    func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Error al cerrar sesión: \(error.localizedDescription)")
            self.errorMessage = error.localizedDescription
        }
    }
    
    // Fichero: RondaApp/Core/Managers/SessionManager.swift

    // Reemplaza tu función `acceptPolicy` por esta versión mejorada.
    func acceptPolicy(firebaseUser: FirebaseAuth.User) {
        Task {
            self.isLoading = true // Mostramos el indicador de carga
            self.errorMessage = nil
            
            do {
                // 1. Creamos un usuario parcial con la política aceptada.
                let partialUser = User(
                    uid: firebaseUser.uid,
                    email: firebaseUser.email,
                    hasAcceptedPolicy: true, // Marcamos la política como aceptada
                    hasCompletedProfile: false // El perfil aún no está completo
                )
                
                // 2. Guardamos este usuario inicial en Firestore.
                try await UserService.shared.createInitialUser(user: partialUser)
                
                // 3. ✅ ¡LA CLAVE ESTÁ AQUÍ!
                //    Forzamos una re-evaluación del estado del usuario.
                //    Esto hará que se lea el nuevo perfil desde Firestore y se actualice la UI.
                await handleUserChange(firebaseUser: firebaseUser)
                
            } catch {
                // Manejo de errores
                let errorMessageText = "No se pudo guardar la aceptación de la política. Por favor, inténtalo de nuevo. Error: \(error.localizedDescription)"
                print(errorMessageText)
                self.errorMessage = errorMessageText
            }
            
            self.isLoading = false // Ocultamos el indicador de carga
        }
    }
    
    func completeProfile(user: User, username: String, age: String, imageData: Data?) {
        Task {
            self.isLoading = true
            self.errorMessage = nil
            
            // Validamos que la edad sea un número válido antes de continuar.
            guard let ageInt = Int(age) else {
                self.errorMessage = "La edad debe ser un número válido."
                self.isLoading = false
                return
            }
            
            // Validamos que tengamos un usuario autenticado activo.
            guard let firebaseUser = Auth.auth().currentUser else {
                self.errorMessage = "No se ha encontrado un usuario activo. Por favor, reinicia la aplicación."
                self.isLoading = false
                return
            }
            
            do {
                // 1. Llamamos al servicio para que suba la imagen (si la hay)
                //    y actualice los datos del usuario en Firestore.
                try await UserService.shared.updateUserProfile(
                    userId: user.uid,
                    username: username,
                    age: ageInt,
                    imageData: imageData
                )
                
                // 2. ✅ ¡LA SOLUCIÓN DEFINITIVA!
                //    Una vez que el perfil está completo en la base de datos,
                //    forzamos la re-evaluación del estado.
                await handleUserChange(firebaseUser: firebaseUser)
                
            } catch {
                let errorMessageText = "No se pudo guardar tu perfil. Por favor, inténtalo de nuevo. Error: \(error.localizedDescription)"
                print(errorMessageText)
                self.errorMessage = errorMessageText
            }
            
            // 3. Ocultamos el indicador de carga. Si todo fue bien, handleUserChange
            //    ya habrá provocado la navegación a la pantalla principal.
            self.isLoading = false
        }
    }
}
