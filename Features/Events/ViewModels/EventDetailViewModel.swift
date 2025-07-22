// Fichero: RondaApp/Features/Events/ViewModels/EventDetailViewModel.swift (Actualizado)

import Foundation
import Combine

// ✅ 1. Nuevo struct para el leaderboard, ahora con el desglose de bebidas
struct EventLeaderboardEntry: Identifiable, Equatable {
    let id: String // Usaremos el User ID
    let user: User
    let totalDrinks: Int
    let drinkCounts: [String: Int] // [DrinkID: Count]
}

@MainActor
class EventDetailViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // ✅ El leaderboard ahora usa nuestro nuevo modelo
    @Published var leaderboard: [EventLeaderboardEntry] = []
    
    // ✅ Propiedad para guardar la lista de bebidas de la sala
    @Published var allDrinksInRoom: [Drink] = []

    private var eventId: String
    private var roomId: String
    private var cancellables = Set<AnyCancellable>()

    init(eventId: String, roomId: String) {
        self.eventId = eventId
        self.roomId = roomId
        fetchEventDetails()
    }

    private func fetchEventDetails() {
        isLoading = true
        Task {
            do {
                // Obtenemos el evento Y la sala (para las bebidas) en paralelo para más eficiencia
                async let fetchedEvent = EventService.shared.fetchEvent(id: eventId, inRoomId: roomId)
                async let fetchedRoom = RoomService.shared.fetchRoom(withId: roomId) // Necesitamos esta función en RoomService
                
                // Esperamos a que ambas operaciones terminen
                self.event = try await fetchedEvent
                let room = try await fetchedRoom
                self.allDrinksInRoom = room.drinks
                
                // Una vez tenemos todos los datos, calculamos el leaderboard
                await self.calculateLeaderboard()
                
                self.isLoading = false
            } catch {
                self.errorMessage = "Error al cargar los detalles del evento: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }

    private func calculateLeaderboard() async {
        guard let event = event else { return }

        // Agrupamos las bebidas consumidas por cada usuario
        let drinksByUser = Dictionary(grouping: event.drinksConsumed, by: { $0.userId })
        
        var fetchedLeaderboard: [EventLeaderboardEntry] = []
        
        for (userId, entries) in drinksByUser {
            do {
                let user = try await UserService.shared.fetchUser(withId: userId)
                // Contamos cuántas veces aparece cada drinkId para este usuario
                let counts = Dictionary(grouping: entries, by: { $0.drinkId }).mapValues { $0.count }
                
                fetchedLeaderboard.append(
                    EventLeaderboardEntry(
                        id: userId,
                        user: user,
                        totalDrinks: entries.count,
                        drinkCounts: counts
                    )
                )
            } catch {
                print("Error fetching user \(userId): \(error.localizedDescription)")
            }
        }
        
        self.leaderboard = fetchedLeaderboard.sorted { $0.totalDrinks > $1.totalDrinks }
    }
}
