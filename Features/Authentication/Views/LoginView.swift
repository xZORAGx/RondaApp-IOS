// Fichero: RondaApp/Features/Authentication/Views/LoginView.swift

import SwiftUI
import AuthenticationServices // Importante: Añadir esta línea

struct LoginView: View {
    @ObservedObject var sessionManager: SessionManager

    var body: some View {
        ZStack {
            Color(red: 236/255, green: 224/255, blue: 202/255)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()
                
                Image("AppRondaapp")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .padding(.bottom, 60)

                // ✅ CÓDIGO CORREGIDO: Botón nativo de Apple
                SignInWithAppleButton(
                    .signIn,
                    onRequest: { request in
                        sessionManager.handleAppleSignInRequest(request)
                    },
                    onCompletion: { result in
                        sessionManager.handleAppleSignInCompletion(result)
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 55)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
                .padding(.horizontal) // Usamos padding horizontal completo como en el de Google

                Button(action: {
                    sessionManager.signInWithGoogle()
                }) {
                    HStack {
                        Image("GoogleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Iniciar sesión con Google").fontWeight(.medium)
                    }
                }
                .buttonStyle(SocialButtonStyle(
                    backgroundColor: .white,
                    foregroundColor: .black.opacity(0.8),
                    strokeColor: .gray.opacity(0.3)
                ))

                Spacer()
                
                Text("Debes ser mayor de edad para registrarte.")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding()
            
            if sessionManager.isLoading {
                LoadingView()
            }
        }
        .alert("Error de Autenticación", isPresented: .constant(sessionManager.errorMessage != nil), actions: {
            Button("OK", role: .cancel) {
                sessionManager.errorMessage = nil
            }
        }, message: {
            Text(sessionManager.errorMessage ?? "Ha ocurrido un error desconocido.")
        })
    }
}

// --- VISTAS Y ESTILOS REUTILIZABLES ---
// (Tu código existente se mantiene igual)

struct SocialButtonStyle: ButtonStyle {
    var backgroundColor: Color
    var foregroundColor: Color
    var strokeColor: Color = .clear

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(strokeColor, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 3, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(2)
                .tint(.white)
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView(sessionManager: SessionManager())
}
