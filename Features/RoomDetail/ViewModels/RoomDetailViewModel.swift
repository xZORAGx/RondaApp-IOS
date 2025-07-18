// Fichero: RondaApp/Features/RoomDetail/ViewModels/RoomDetailViewModel.swift

import Foundation
import Combine
import CoreLocation // ✅ ESTA ES LA LÍNEA QUE AÑADIMOS

@MainActor
class RoomDetailViewModel: ObservableObject {
    
    // --- Published Properties ---
    @Published var leaderboardEntries: [LeaderboardEntry] = []
    @Published var room: Room
    @Published var errorMessage: String?
    @Published var isLoading: Bool = false
    @Published var roomMembers: [User] = []
    @Published var betToWagerOn: Bet?
    @Published var duels: [Duel] = []
    @Published var duelToResolve: Duel?
    
    // ✅ Las apuestas ahora se cargan en su propia propiedad desde la subcolección
    @Published var bets: [Bet] = []

    // --- Private Properties ---
    private var cancellables = Set<AnyCancellable>()
    private let roomService = RoomService.shared
    private let userService = UserService.shared
    private let locationManager = LocationManager()
    let currentUser: User?
    
    // --- Initializer ---
    init(room: Room, user: User) {
        self.room = room
        self.currentUser = user
        // ✅ Renombramos para más claridad, ahora configura ambos listeners
        setupListeners()
    }
    
    // --- Computed Properties ---
    var isUserAdmin: Bool {
        return currentUser?.uid == room.ownerId
    }
    
    var currentUserCredits: Int {
        guard let userId = currentUser?.uid else { return 0 }
        return room.userCredits[userId] ?? 0
    }
    
    // --- Lógica de Apuestas ---
    func createBet(_ bet: Bet) async -> Bool {
        guard let roomId = room.id else {
            errorMessage = "ID de sala no encontrado."
            return false
        }
        
        isLoading = true; errorMessage = nil
        do {
            try await roomService.createBet(bet, inRoomId: roomId)
            isLoading = false; return true
        } catch {
            errorMessage = "Error al crear la apuesta: \(error.localizedDescription)"
            isLoading = false; return false
        }
    }
    
    func placeWager(on bet: Bet, amount: Int) async {
        guard let roomId = room.id, let userId = currentUser?.uid, let betId = bet.id else {
            errorMessage = "Datos insuficientes para realizar la apuesta."
            return
        }
        
        betToWagerOn = nil; isLoading = true; errorMessage = nil
        do {
            try await roomService.placeWager(betId: betId, userId: userId, amount: amount, inRoomId: roomId)
        } catch {
            errorMessage = "Error al apostar: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func resolveBet(bet: Bet, newStatus: BetStatus) async {
        guard let roomId = room.id, let betId = bet.id else {
            errorMessage = "Datos insuficientes para resolver la apuesta."
            return
        }
        
        isLoading = true; errorMessage = nil
        do {
            try await roomService.resolveBet(betId: betId, newStatus: newStatus, inRoomId: roomId)
        } catch {
            errorMessage = "Error al resolver la apuesta: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // --- Listeners ---
    // ✅ Función actualizada para configurar ambos listeners
    private func setupListeners() {
        guard let roomId = room.id else { return }
        
        // Listener para la información general de la sala
        roomService.listenToRoomUpdates(roomId: roomId)
            .sink { completion in
                if case .failure(let error) = completion { self.errorMessage = "Error de conexión: \(error.localizedDescription)" }
            } receiveValue: { [weak self] updatedRoom in
                self?.room = updatedRoom
                self?.fetchUsersAndLeaderboard()
            }
            .store(in: &cancellables)
            
        // Listener para la subcolección de apuestas
        roomService.listenToBets(inRoomId: roomId)
            .sink { completion in
                 if case .failure(let error) = completion { self.errorMessage = "Error cargando apuestas: \(error.localizedDescription)" }
            } receiveValue: { [weak self] newBets in
                // Ordenamos las apuestas para que las más nuevas (o pendientes) aparezcan primero
                self?.bets = newBets.sorted(by: { $0.deadline.dateValue() > $1.deadline.dateValue() })
            }
            .store(in: &cancellables)
        
        roomService.listenToDuels(inRoomId: roomId)
                    .sink { completion in
                         if case .failure(let error) = completion { self.errorMessage = "Error cargando duelos: \(error.localizedDescription)" }
                    } receiveValue: { [weak self] newDuels in
                        self?.duels = newDuels.sorted(by: { $0.startTime.dateValue() > $1.startTime.dateValue() })
                    }
                    .store(in: &cancellables)
            
    }
    
    // --- Lógica de la Clasificación y Administración ---
    private func fetchUsersAndLeaderboard() {
        guard !room.memberIds.isEmpty else {
            self.leaderboardEntries = []
            self.roomMembers = []
            return
        }
        
        Task {
            do {
                let users = try await userService.fetchUsers(withIDs: room.memberIds)
                self.roomMembers = users
                
                var entries = users.map { user -> LeaderboardEntry in
                    let userDrinkCounts = self.room.scores[user.uid] ?? [:]
                    let totalScore = userDrinkCounts.reduce(0) { currentScore, drinkCountPair in
                        let (drinkId, count) = drinkCountPair
                        let pointsPerDrink = self.room.drinks.first { $0.id == drinkId }?.points ?? 0
                        return currentScore + (count * pointsPerDrink)
                    }
                    return LeaderboardEntry(user: user, score: totalScore, userScores: userDrinkCounts)
                }
                
                entries.sort { $0.score > $1.score }
                self.leaderboardEntries = entries
                
            } catch {
                self.errorMessage = "Error al cargar los miembros: \(error.localizedDescription)"
            }
        }
    }
    
    func add(drink: Drink) {
        Task {
            do {
                guard let userId = currentUser?.uid else { return }
                try await roomService.addDrinkForUser(userId: userId, drinkId: drink.id, in: room)
            } catch {
                self.errorMessage = "No se pudo añadir la bebida: \(error.localizedDescription)"
            }
        }
    }

    func saveDrinkChanges() async throws {
        guard let roomId = room.id else { throw URLError(.badURL) }
        try await roomService.updateDrinks(forRoomId: roomId, with: self.room.drinks)
    }
    
    func addNewDrink() {
        let newDrink = Drink(id: UUID().uuidString, name: "", points: 1, emoji: "")
        self.room.drinks.append(newDrink)
    }

    func deleteDrink(at offsets: IndexSet) async {
        let originalDrinks = self.room.drinks
        self.room.drinks.remove(atOffsets: offsets)
        do {
            try await saveDrinkChanges()
        } catch {
            self.errorMessage = "Error al eliminar la bebida: \(error.localizedDescription)"
            self.room.drinks = originalDrinks
        }
    }
    
    func createDuel(_ duel: Duel) async -> Bool {
            guard let roomId = room.id else { return false }
            
            isLoading = true; errorMessage = nil
            do {
                try await roomService.createDuel(duel, inRoomId: roomId)
                isLoading = false; return true
            } catch {
                errorMessage = "Error al crear el duelo: \(error.localizedDescription)"
                isLoading = false; return false
            }
        }
    
    func resolveDuelAsAdmin(duel: Duel, winnerId: String?) async {
        guard let roomId = room.id else {
            errorMessage = "ID de sala no encontrado."
            return
        }
        
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            try await roomService.resolveDuel(duel: duel, winnerId: winnerId, inRoomId: roomId)
        } catch {
            self.errorMessage = "Error al resolver el duelo: \(error.localizedDescription)"
        }
        
        self.isLoading = false
    }

    func startDuelPoll(for duel: Duel) async {
          guard let roomId = room.id else {
              errorMessage = "ID de sala no encontrado."
              return
          }
          
          self.isLoading = true
          self.errorMessage = nil
          
          do {
              try await roomService.initiateDuelPoll(for: duel, inRoomId: roomId)
          } catch {
              self.errorMessage = "Error al crear la encuesta: \(error.localizedDescription)"
          }
          
          self.isLoading = false
      }
    
    func checkForFinishedAdminDuels() {
            guard let adminId = currentUser?.uid, isUserAdmin else { return }
            
            // Buscamos duelos donde el admin participa, su tiempo ha acabado y aún están en progreso.
            let finishedAdminDuels = duels.filter { duel in
                let isAdminParticipant = duel.challengerId == adminId || duel.opponentId == adminId
                let isTimeUp = duel.endTime.dateValue() < Date()
                return isAdminParticipant && isTimeUp && duel.status == .inProgress
            }
            
            // Si encontramos alguno, iniciamos la encuesta.
            for duel in finishedAdminDuels {
                print("Duelo de admin finalizado detectado. Iniciando encuesta para: \(duel.title)")
                Task {
                    await startDuelPoll(for: duel)
                }
            }
        }
    
    func acceptDuel(duel: Duel) async {
        guard let roomId = room.id else { return }
        isLoading = true; errorMessage = nil
        do {
            try await roomService.acceptDuel(duel: duel, inRoomId: roomId)
        } catch {
            errorMessage = "Error al aceptar el duelo: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    // ✅ NUEVA: Rechazar un duelo
    func declineDuel(duel: Duel) async {
        guard let roomId = room.id else { return }
        isLoading = true; errorMessage = nil
        do {
            try await roomService.declineDuel(duel: duel, inRoomId: roomId)
        } catch {
            errorMessage = "Error al rechazar el duelo: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func createCheckIn(drinkId: String, caption: String?, imageData: Data?, shareLocation: Bool) async -> Bool {
        guard let currentUser = currentUser, let roomId = room.id else {
            errorMessage = "Datos de sesión inválidos."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        var location: CLLocation? = nil
        if shareLocation {
            // Si el usuario quiere compartir ubicación, la obtenemos aquí.
            guard locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways else {
                errorMessage = "No se puede compartir la ubicación. Revisa los permisos en Ajustes."
                isLoading = false
                return false
            }
            location = await getLocation()
        }
        
        do {
            // Llamamos al servicio con todos los datos listos.
            try await roomService.createCheckIn(
                for: currentUser, inRoomId: roomId, drinkId: drinkId,
                caption: caption, imageData: imageData, location: location
            )
            isLoading = false
            return true
        } catch {
            errorMessage = "No se pudo registrar tu momento: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    /// Obtiene la ubicación de forma segura.
    private func getLocation() async -> CLLocation? {
        locationManager.startUpdatingLocation()
        for _ in 0..<30 { // Esperamos un máximo de 3 segundos
            if let loc = locationManager.userLocation { return loc }
            try? await Task.sleep(for: .milliseconds(100))
        }
        return locationManager.userLocation
    }
        
    
}
