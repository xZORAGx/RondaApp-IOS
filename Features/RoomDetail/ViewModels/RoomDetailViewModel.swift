// Fichero: RondaApp/Features/RoomDetail/ViewModels/RoomDetailViewModel.swift

import Foundation
import Combine

@MainActor
class RoomDetailViewModel: ObservableObject {
    
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var room: Room
    @Published var errorMessage: String?
    
    private var cancellables = Set<AnyCancellable>()
    private let roomService = RoomService.shared
    private let userService = UserService.shared
    private let user: User
    
    init(room: Room, user: User) {
        self.room = room
        self.user = user
        
        // --- TRAZA 1 ---
        print("✅ VM INIT: ViewModel inicializado para la sala '\(room.title)'")
        
        setupRoomListener()
        fetchUsersForLeaderboard()
    }
    
    private func setupRoomListener() {
        roomService.listenToRoomUpdates(roomId: room.id ?? "ID_NULO")
            .sink { completion in
                if case .failure(let error) = completion {
                    // --- TRAZA DE ERROR ---
                    print("❌ VM LISTENER ERROR: El listener falló con error: \(error.localizedDescription)")
                    self.errorMessage = "Error de conexión: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] updatedRoom in
                // --- TRAZA 2 ---
                print("🔄 VM LISTENER UPDATE: Datos de la sala actualizados en tiempo real.")
                self?.room = updatedRoom
                self?.fetchUsersForLeaderboard()
            }
            .store(in: &cancellables)
    }
    
    private func fetchUsersForLeaderboard() {
        // --- TRAZA 3 ---
        print("🚀 VM FETCH: Iniciando carga del leaderboard. Miembros a buscar: \(room.memberIds)")
        
        guard !room.memberIds.isEmpty else {
            print("⚠️ VM FETCH WARNING: La lista de 'memberIds' está vacía. No se carga nada.")
            self.leaderboardEntries = []
            return
        }
        
        Task {
            do {
                let users = try await userService.fetchUsers(withIDs: room.memberIds)
                // --- TRAZA 4 ---
                print("👍 VM FETCH SUCCESS: Se encontraron \(users.count) perfiles de usuario.")
                
                var entries = users.map { user in
                    LeaderboardEntry(
                        user: user,
                        score: self.room.scores?[user.uid] ?? 0
                    )
                }
                
                entries.sort { $0.score > $1.score }
                
                self.leaderboardEntries = entries
                // --- TRAZA 5 ---
                print("✅ VM FETCH COMPLETE: El leaderboard se ha procesado y actualizado con \(entries.count) entradas.")
                
            } catch {
                // --- TRAZA DE ERROR ---
                print("❌ VM FETCH ERROR: Fallo al buscar los perfiles de usuario: \(error.localizedDescription)")
                self.errorMessage = "Error al cargar los miembros: \(error.localizedDescription)"
            }
        }
    }
    
    func addDrink() {
        Task {
            do {
                try await roomService.addDrinkForUser(userId: user.uid, in: room)
            } catch {
                print("❌ VM ADDRINK ERROR: \(error.localizedDescription)")
                self.errorMessage = "No se pudo añadir la bebida: \(error.localizedDescription)"
            }
        }
    }
}
