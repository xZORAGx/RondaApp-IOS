// Fichero: RondaApp/Features/RoomList/ViewModels/RoomListViewModel.swift

import Foundation
import Combine
import FirebaseAuth

@MainActor
class RoomListViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var rooms: [Room] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Properties
    
    private let user: User
    
    // MARK: - Initializer
    
    init(user: User) {
        self.user = user
        loadRooms()
    }
    
    // MARK: - Public Methods
    
    /// Carga las salas del usuario actual desde el servicio de Firebase.
    func loadRooms() {
        self.isLoading = true
        self.errorMessage = nil
        
        Task {
            do {
                self.rooms = try await RoomService.shared.fetchRooms(forUser: user.uid)
            } catch {
                self.errorMessage = "Error al cargar las salas: \(error.localizedDescription)"
            }
            self.isLoading = false
        }
    }
    
    
    /// Crea una nueva sala con los datos proporcionados y una imagen opcional.
    func createRoom(title: String, description: String, imageData: Data?) async -> Bool {
        isLoading = true
        var success = false
        
        do {
            // 1. Crear la sala en Firestore a través del servicio.
            let roomId = try await RoomService.shared.createRoom(title: title, description: description, owner: user)
            
            // 2. Si el usuario proporcionó una imagen, se sube y se actualiza la sala.
            if let data = imageData {
                // ✅ PASO CORREGIDO 1: Sube la imagen a Storage y obtén la URL.
                let url = try await StorageService.shared.uploadRoomImage(imageData: data, roomId: roomId)
                
                // ✅ PASO CORREGIDO 2: Actualiza Firestore con la URL (convertida a String).
                try await RoomService.shared.updateRoomPhotoURL(roomId: roomId, url: url.absoluteString)
            }
            
            // 3. Recargamos la lista para que la nueva sala aparezca inmediatamente.
            loadRooms()
            success = true
            
        } catch {
            errorMessage = "Error al crear la sala: \(error.localizedDescription)"
            success = false
        }
        
        isLoading = false
        return success
    }
    func leaveRoom(_ room: Room) {
            isLoading = true
            errorMessage = nil

            Task {
                do {
                    // Llama al servicio para ejecutar la lógica de borrado en Firebase
                    try await RoomService.shared.leaveRoom(room, userId: user.uid)
                    
                    // Opción 1 (Recomendada): Elimina la sala de la lista local para una UI instantánea
                    rooms.removeAll { $0.id == room.id }

            
                } catch {
                    self.errorMessage = "Error al salir de la sala: \(error.localizedDescription)"
                }
                isLoading = false
            }
        }
    }

