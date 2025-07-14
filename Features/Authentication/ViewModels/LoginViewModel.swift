// Fichero: RondaApp/Features/Authentication/ViewModels/LoginViewModel.swift
// ✅ VERSIÓN CORREGIDA Y FINAL

import Foundation

@MainActor
class LoginViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // La función signInWithApple() ha sido eliminada.
    // La LoginView ahora usa directamente el SessionManager para Apple Sign In.
    
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
