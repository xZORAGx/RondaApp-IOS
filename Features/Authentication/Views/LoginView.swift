//  RondaApp/Features/Authentication/Views/LoginView.swift

import SwiftUI

// MARK: - Color Extension
// Para una mejor organización, esto debería ir en un archivo como "Color+Extensions.swift".
extension Color {
    // Color exacto: #ece0ca
    static let logoBackground = Color(red: 236/255, green: 224/255, blue: 202/255)
}

// MARK: - Login View
struct LoginView: View {
    // Instanciamos nuestro ViewModel para manejar la lógica y el estado.
    @StateObject private var viewModel = LoginViewModel()

    var body: some View {
        ZStack {
            // Fondo con el color personalizado.
            Color.logoBackground
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                Spacer()
                
                // Logo de la aplicación.
                Image("AppRondaapp") // Asegúrate de tener esta imagen en Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .padding(.bottom, 60)

                // Botón de inicio de sesión con Apple (deshabilitado).
                Button(action: {
                    viewModel.signInWithApple()
                }) {
                    HStack {
                        Image(systemName: "apple.logo")
                            .font(.title2)
                        Text("Iniciar sesión con Apple")
                            .fontWeight(.semibold)
                    }
                }
                .buttonStyle(SocialButtonStyle(backgroundColor: .black, foregroundColor: .white))
                .disabled(true) // El botón no se puede pulsar.
                .opacity(0.6)   // Se muestra visualmente como deshabilitado.

                // Botón de inicio de sesión con Google (funcional).
                Button(action: {
                    viewModel.signInWithGoogle()
                }) {
                    HStack {
                        Image("GoogleLogo") // Asegúrate de tener esta imagen en Assets.xcassets
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Iniciar sesión con Google")
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(SocialButtonStyle(backgroundColor: .white,
                                             foregroundColor: .black.opacity(0.8),
                                             strokeColor: .gray.opacity(0.3)))

                Spacer()
                
                // Texto legal o informativo.
                Text("Debes ser mayor de edad para registrarte.")
                    .font(.caption)
                    .foregroundColor(.black.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

            }
            .padding()
            
            // Vista de carga que se superpone cuando isLoading es true.
            if viewModel.isLoading {
                LoadingView()
            }
        }
        // Alerta para mostrar mensajes de error desde el ViewModel.
        .alert("Error de Autenticación", isPresented: .constant(viewModel.errorMessage != nil), actions: {
            Button("OK", role: .cancel) {
                viewModel.errorMessage = nil
            }
        }, message: {
            Text(viewModel.errorMessage ?? "Ha ocurrido un error desconocido.")
        })
    }
}

// MARK: - Reusable Button Style
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

// MARK: - Reusable Loading View
// Para una mejor organización, esto debería ir en un archivo como "LoadingView.swift" en la carpeta Shared/Views.
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
    LoginView()
}
