//  RondaApp/Features/RoomList/ViewModels/RoomListViewModel.swift

import Foundation
import Combine
import FirebaseAuth

@MainActor
class RoomListViewModel: ObservableObject {
    
    @Published var rooms: [Room] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    private let user: User
    
    init(user: User) {
        self.user = user
        loadRooms()
    }
    
    func loadRooms() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                self.rooms = try await RoomService.shared.fetchRooms(forUser: user.uid)
            } catch {
                self.errorMessage = "Error al cargar las salas: \(error.localizedDescription)"
            }
            isLoading = false
        }
    }
    
    // La función ahora acepta datos de imagen opcionales
    func createRoom(title: String, description: String, imageData: Data?) async -> Bool {
        isLoading = true
        var success = false
        do {
            // 1. Crear la sala en Firestore
            let roomId = try await RoomService.shared.createRoom(title: title, description: description, owner: user)
            
            // 2. Si hay una imagen, subirla
            if let data = imageData {
                let url = try await StorageService.shared.uploadRoomImage(imageData: data, roomId: roomId)
                // 3. Actualizar la sala con la URL de la imagen
                try await RoomService.shared.updateRoomPhotoURL(roomId: roomId, url: url)
            }
            
            loadRooms()
            success = true
        } catch {
            errorMessage = "Error al crear la sala: \(error.localizedDescription)"
            success = false
        }
        isLoading = false
        return success
    }
}
