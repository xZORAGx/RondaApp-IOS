// Fichero: RondaApp/Features/RoomDetail/ViewModels/RoomDetailViewModel.swift

import Foundation
import Combine

@MainActor
class RoomDetailViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var room: Room
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private let roomService = RoomService.shared
    private let userService = UserService.shared
    private let user: User
    
    // MARK: - Initializer
    init(room: Room, user: User) {
        self.room = room
        self.user = user
        setupRoomListener()
    }
    
    // MARK: - Computed Properties
    var isUserAdmin: Bool {
        return user.uid == room.ownerId
    }
    
    // MARK: - Public Methods
    
    /// Guarda la lista actual de bebidas en Firestore.
    /// Es la función central para persistir los cambios.
    func saveDrinkChanges() async throws {
        guard let roomId = room.id else {
            throw URLError(.badURL)
        }
        try await roomService.updateDrinks(forRoomId: roomId, with: self.room.drinks)
    }
    
    /// Añade una nueva bebida a la lista local y la guarda inmediatamente en Firestore.
    func addNewDrink() {
        // Creamos una bebida con un ID único para poder identificarla en la UI.
        let newDrink = Drink(id: UUID().uuidString, name: "", points: 1, emoji: "")
        self.room.drinks.append(newDrink)
    }

    /// Elimina una o más bebidas de la lista local y guarda los cambios inmediatamente en Firestore.
    func deleteDrink(at offsets: IndexSet) async {
        let originalDrinks = self.room.drinks
        self.room.drinks.remove(atOffsets: offsets)
        
        do {
            try await saveDrinkChanges()
        } catch {
            self.errorMessage = "Error al eliminar la bebida: \(error.localizedDescription)"
            // Si falla el guardado, restauramos la lista original para mantener la consistencia.
            self.room.drinks = originalDrinks
        }
    }
    
    /// Registra que un usuario ha consumido una bebida.
    func add(drink: Drink) {
        Task {
            do {
                try await roomService.addDrinkForUser(userId: user.uid, drinkId: drink.id, in: room)
            } catch {
                self.errorMessage = "No se pudo añadir la bebida: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func setupRoomListener() {
        roomService.listenToRoomUpdates(roomId: room.id ?? "ID_NULO")
            .sink { completion in
                if case .failure(let error) = completion {
                    self.errorMessage = "Error de conexión: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] updatedRoom in
                self?.room = updatedRoom
                self?.fetchUsersForLeaderboard()
            }
            .store(in: &cancellables)
    }
    
    private func fetchUsersForLeaderboard() {
        guard !room.memberIds.isEmpty else {
            self.leaderboardEntries = []
            return
        }
        
        Task {
            do {
                let users = try await userService.fetchUsers(withIDs: room.memberIds)
                
                var entries = users.map { user -> LeaderboardEntry in
                    let userDrinkCounts = self.room.scores[user.uid] ?? [:]
                    
                    let totalScore = userDrinkCounts.reduce(0) { currentScore, drinkCountPair in
                        let (drinkId, count) = drinkCountPair
                        let pointsPerDrink = self.room.drinks.first { $0.id == drinkId }?.points ?? 0
                        return currentScore + (count * pointsPerDrink)
                    }
                    
                    return LeaderboardEntry(
                        user: user,
                        score: totalScore,
                        userScores: userDrinkCounts
                    )
                }
                
                entries.sort { $0.score > $1.score }
                
                self.leaderboardEntries = entries
                
            } catch {
                self.errorMessage = "Error al cargar los miembros: \(error.localizedDescription)"
            }
        }
    }
}
