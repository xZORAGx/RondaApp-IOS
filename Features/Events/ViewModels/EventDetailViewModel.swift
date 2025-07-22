//
//  EventDetailViewModel.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import Foundation
import Combine

@MainActor
class EventDetailViewModel: ObservableObject {
    @Published var event: Event?
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var leaderboard: [UserScore] = []

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
                let fetchedEvent = try await EventService.shared.fetchEvent(id: eventId, inRoomId: roomId)
                self.event = fetchedEvent
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

        var userDrinkCounts: [String: Int] = [:]
        for entry in event.drinksConsumed {
            userDrinkCounts[entry.userId, default: 0] += 1
        }

        var fetchedLeaderboard: [UserScore] = []
        for (userId, count) in userDrinkCounts {
            do {
                let user = try await UserService.shared.fetchUser(withId: userId)
                fetchedLeaderboard.append(UserScore(userId: userId, username: user.username ?? "Usuario Desconocido", score: count))
            } catch {
                print("Error fetching user \(userId): \(error.localizedDescription)")
                fetchedLeaderboard.append(UserScore(userId: userId, username: "Usuario Desconocido", score: count))
            }
        }
        self.leaderboard = fetchedLeaderboard.sorted { $0.score > $1.score }
    }

    func generateRewind() {
        // This will trigger the RewindViewModel or a navigation to the RewindView
        print("Generating Rewind for event: \(eventId)")
    }
}

struct UserScore: Identifiable, Equatable {
    let id = UUID()
    let userId: String
    let username: String
    let score: Int
}