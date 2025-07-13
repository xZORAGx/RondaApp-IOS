//  RondaApp/Features/RoomList/Views/CreateRoomView.swift

import SwiftUI
import PhotosUI

struct CreateRoomView: View {
    
    @ObservedObject var viewModel: RoomListViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var title: String = ""
    @State private var description: String = ""
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        imagePlaceholder
                    }
                    .onChange(of: selectedPhotoItem) {
                        Task {
                            if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) {
                                selectedImageData = data
                            }
                        }
                    }
                    
                    VStack(spacing: 16) {
                        TextField("Título de la sala", text: $title)
                            .modifier(CustomTextFieldModifier(icon: "text.quote"))
                        
                        TextField("Descripción (opcional)", text: $description)
                            .modifier(CustomTextFieldModifier(icon: "text.alignleft"))
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nueva Sala")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Crear") { createRoom() }
                        .fontWeight(.bold)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                }
            }
        }
    }
    
    private func createRoom() {
        Task {
            let success = await viewModel.createRoom(title: title, description: description, imageData: selectedImageData)
            if success {
                dismiss()
            }
        }
    }
    
    private var imagePlaceholder: some View {
        Group {
            if let data = selectedImageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack {
                    Image(systemName: "camera.fill")
                        .font(.largeTitle)
                    Text("Añadir foto")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(width: 150, height: 150)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.secondary, lineWidth: 2).opacity(0.3))
    }
}

// MARK: - Modificador de Estilo para los TextFields
struct CustomTextFieldModifier: ViewModifier {
    let icon: String
    
    func body(content: Content) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            content
        }
        .padding()
        // ✅ SOLUCIÓN: Usamos un color que se adapta al modo claro/oscuro.
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        // La sombra se ve mejor en modo claro, la hacemos más sutil en oscuro.
        .shadow(color: .black.opacity(0.05), radius: 3, y: 1)
    }
}

#Preview {
    let user = User(uid: "123", email: "test@test.com", username: "Test", age: 20, hasAcceptedPolicy: true, hasCompletedProfile: true)
    let vm = RoomListViewModel(user: user)
    // Para probar el modo oscuro en la preview:
    return CreateRoomView(viewModel: vm)
        .preferredColorScheme(.dark)
}
