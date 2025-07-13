// Fichero: RondaApp/Features/RoomList/Views/CreateRoomView.swift

import SwiftUI
import PhotosUI

struct CreateRoomView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: RoomListViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            // ✅ SOLUCIÓN: Usamos un Form en lugar de ScrollView + VStack.
            // Form está optimizado para pantallas con campos de entrada de datos.
            Form {
                // Sección para la imagen
                Section {
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            imagePlaceholder
                        }
                        .onChange(of: selectedPhotoItem, perform: loadImage)
                        Spacer()
                    }
                    .padding(.vertical)
                }
                
                // Sección para la información
                Section(header: Text("Información de la Sala")) {
                    TextField("Título de la sala", text: $title)
                    TextField("Descripción (opcional)", text: $description)
                }
                
                // Sección para el botón de acción
                Section {
                    Button(action: createRoom) {
                        Text("Crear Sala")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .disabled(isButtonDisabled())
                }
            }
            .navigationTitle("Nueva Sala")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    // El botón principal ahora está en la sección del Form,
                    // pero podrías mantenerlo aquí si lo prefieres.
                }
            }
        }
    }
    
    // MARK: - Helper Views and Functions
    
    /// La vista que muestra la imagen seleccionada o un placeholder.
    @ViewBuilder
    private var imagePlaceholder: some View {
        if let data = selectedImageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 150, height: 150)
                .clipShape(Circle())
        } else {
            VStack {
                Image(systemName: "camera.fill")
                    .font(.largeTitle)
                Text("Añadir foto")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            .frame(width: 150, height: 150)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.secondary, lineWidth: 2).opacity(0.3))
        }
    }
    
    /// Carga los datos de la imagen seleccionada.
    private func loadImage(from item: PhotosPickerItem?) {
        Task {
            if let data = try? await item?.loadTransferable(type: Data.self) {
                selectedImageData = data
            }
        }
    }
    
    /// Lógica para crear la sala.
    private func createRoom() {
        Task {
            let success = await viewModel.createRoom(
                title: title,
                description: description,
                imageData: selectedImageData
            )
            if success {
                dismiss()
            }
        }
    }
    
    /// Determina si el botón de crear debe estar deshabilitado.
    private func isButtonDisabled() -> Bool {
        return title.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading
    }
}

// MARK: - Preview
#Preview {
    // Asegúrate de tener un modelo User de ejemplo para que la preview funcione
    let user = User(uid: "123", email: "test@test.com", username: "TestUser", age: 21, hasAcceptedPolicy: true, hasCompletedProfile: true)
    let vm = RoomListViewModel(user: user)
    return CreateRoomView(viewModel: vm)
}
