// Fichero: RondaApp/Features/Authentication/Views/CreateProfileView.swift

import SwiftUI
import PhotosUI

struct CreateProfileView: View {

    // MARK: - Properties
    
    // Este es el 'completion handler'. Es la función que la vista ejecutará cuando termine.
    private let onComplete: (String, String, Data?) -> Void
    
    // Estados internos de la vista para los campos del formulario
    @State private var username: String = ""
    @State private var ageString: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    @State private var isLoading = false
    
    // MARK: - Initializer
    
    // ✅ ESTE ES EL INICIALIZADOR CORRECTO
    // Acepta un 'user' y el 'closure' que le pasa la RootView.
    init(user: User, onComplete: @escaping (String, String, Data?) -> Void) {
        // No necesitamos guardar el 'user' porque no lo usamos aquí.
        self.onComplete = onComplete
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Completa tu perfil")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                profileImagePlaceholder
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImageData = data
                    }
                }
            }
            
            VStack(spacing: 16) {
                TextField("Tu nombre de usuario", text: $username)
                TextField("Tu edad", text: $ageString)
                    .keyboardType(.numberPad)
            }
            .modifier(CustomTextFieldModifier(icon: nil))
            
            Spacer()
            
            Button(action: saveProfile) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Guardar y Empezar")
                }
            }
            .font(.headline)
            .fontWeight(.bold)
            .padding()
            .frame(maxWidth: .infinity)
            .background(isFormValid() ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(15)
            .disabled(!isFormValid() || isLoading)
        }
        .padding()
    }
    
    // MARK: - Helper Functions & Views
    
    private func saveProfile() {
        isLoading = true
        // ✅ Cuando se pulsa el botón, llamamos al closure y pasamos los datos.
        onComplete(username, ageString, selectedImageData)
    }
    
    private func isFormValid() -> Bool {
        return !username.trimmingCharacters(in: .whitespaces).isEmpty && Int(ageString) != nil
    }
    
    @ViewBuilder
    private var profileImagePlaceholder: some View {
        if let data = selectedImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
        } else {
            VStack {
                Image(systemName: "camera.fill").font(.largeTitle)
                Text("Añadir foto").font(.caption)
            }
            .foregroundColor(.secondary)
            .frame(width: 150, height: 150)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Circle())
        }
    }
}
