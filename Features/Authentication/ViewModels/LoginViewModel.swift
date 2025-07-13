//  RondaApp/Features/Authentication/ViewModels/LoginViewModel.swift

import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    func signInWithApple() {
        // ✅ SOLUCIÓN: Eliminamos el Task, do-catch y try-await innecesarios
        // Simplemente llamamos a la función (que actualmente no hace nada)
        AuthService.shared.signInWithApple()
    }
    
    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                let _ = try await AuthService.shared.signInWithGoogle()
                // La navegación ahora la gestiona el SessionManager/RootView
            } catch {
                errorMessage = "Error con Google Sign In: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
}
