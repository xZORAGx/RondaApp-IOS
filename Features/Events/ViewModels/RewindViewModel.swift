
//
//  RewindViewModel.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import Foundation
import Combine

struct PlayerScore: Identifiable {
    let id = UUID()
    let userId: String
    let username: String
    let count: Int
}

class RewindViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String? = nil

    @Published var totalDrinks: Int = 0
    @Published var mostPopularDrink: (drinkId: String, count: Int)?
    @Published var topPlayers: [PlayerScore] = []
    @Published var personalSummary: (userId: String, drinkId: String, count: Int)?

    private var eventId: String
    private var currentUserId: String
    private var roomId: String // New property

    init(eventId: String, currentUserId: String, roomId: String) {
        self.eventId = eventId
        self.currentUserId = currentUserId
        self.roomId = roomId
        loadRewindData()
    }

    private func loadRewindData() {
        isLoading = true
        Task {
            do {
                let fetchedEvent = try await EventService.shared.fetchEvent(id: eventId, inRoomId: roomId)
                DispatchQueue.main.async {
                    self.event = fetchedEvent
                }
                await processEventData() // Call async function within a Task
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error al cargar los datos del Rewind: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }

    private func processEventData() async {
        guard let event = event else { return }

        // Calculate total drinks
        totalDrinks = event.drinksConsumed.count

        // Calculate most popular drink
        let drinkCounts = Dictionary(grouping: event.drinksConsumed, by: { $0.drinkId })
            .mapValues { $0.count }
        mostPopularDrink = drinkCounts.max { $0.value < $1.value }.map { (drinkId: $0.key, count: $0.value) }

        // Calculate top players
        let playerDrinkCounts = Dictionary(grouping: event.drinksConsumed, by: { $0.userId })
            .mapValues { $0.count }

        // Fetch usernames for top players
        let sortedPlayers = playerDrinkCounts.sorted { $0.value > $1.value }
        var fetchedTopPlayers: [PlayerScore] = []
        for (userId, count) in sortedPlayers.prefix(3) {
            do {
                let user = try await UserService.shared.fetchUser(withId: userId)
                fetchedTopPlayers.append(PlayerScore(userId: userId, username: user.username ?? "Usuario Desconocido", count: count))
            } catch {
                print("Error fetching user \(userId) for top players: \(error.localizedDescription)")
                fetchedTopPlayers.append(PlayerScore(userId: userId, username: "Usuario Desconocido", count: count))
            }
        }
        // Ensure UI updates happen on main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.topPlayers = fetchedTopPlayers
        }

        // Personal summary
        if let personalDrinks = event.drinksConsumed.filter({ $0.userId == self.currentUserId }).first {
            let personalDrinkCount = event.drinksConsumed.filter({ $0.userId == self.currentUserId && $0.drinkId == personalDrinks.drinkId }).count
            do {
                let user = try await UserService.shared.fetchUser(withId: self.currentUserId)
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.personalSummary = (userId: self.currentUserId, drinkId: personalDrinks.drinkId, count: personalDrinkCount)
                }
            } catch {
                print("Error fetching current user for personal summary: \(error.localizedDescription)")
                // Ensure UI updates happen on main thread
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.personalSummary = (userId: self.currentUserId, drinkId: personalDrinks.drinkId, count: personalDrinkCount)
                }
            }
        }
    }

    func shareRewind() {
        // Logic to generate a shareable image/video and present a share sheet
        print("Sharing Rewind...")
    }
}
