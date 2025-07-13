//  RondaApp/Features/Authentication/Views/CreateProfileView.swift

import SwiftUI

struct CreateProfileView: View {
    
    let user: User
    var onProfileComplete: (String, Int) -> Void
    
    @State private var username: String = ""
    @State private var ageString: String = ""
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Text("Crea tu Perfil")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Elige un nombre de usuario con el que te verán tus amigos.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            TextField("Nombre de usuario", text: $username)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            TextField("Edad", text: $ageString)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
            
            Button(action: validateAndSubmit) {
                Text("Guardar y Entrar")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
            
            Spacer()
        }
        .padding()
    }
    
    private func validateAndSubmit() {
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "El nombre de usuario no puede estar vacío."
            return
        }
        
        guard let age = Int(ageString), age >= 18 else {
            errorMessage = "Debes tener 18 años o más para usar la aplicación."
            return
        }
        
        errorMessage = nil
        onProfileComplete(username, age)
    }
}

#Preview {
    CreateProfileView(user: User(uid: "123", email: "test@test.com"), onProfileComplete: { _,_  in })
}
