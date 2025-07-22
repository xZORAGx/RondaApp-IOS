
//
//  CreateEventViewModel.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import Foundation
import Combine

class CreateEventViewModel: ObservableObject {
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date().addingTimeInterval(7 * 24 * 60 * 60) // 7 days from now
    @Published var selectedParticipants: [User] = [] // Array of User objects
    @Published var availableUsers: [User] = []
    @Published var isLoadingUsers = false
    @Published var customColor: String = "#007AFF" // Default blue
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    @Published var eventCreatedSuccessfully = false

    var roomId: String // This should be set when the view model is initialized

    private var cancellables = Set<AnyCancellable>()

    init(roomId: String) {
        self.roomId = roomId
        fetchAvailableUsers()
    }

    private func fetchAvailableUsers() {
        isLoadingUsers = true
        Task {
            do {
                let users = try await UserService.shared.fetchAllUsers()
                DispatchQueue.main.async {
                    self.availableUsers = users
                    self.isLoadingUsers = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Error al cargar usuarios: \(error.localizedDescription)"
                    self.isLoadingUsers = false
                }
            }
        }
    }

    func createEvent() async {
        isLoading = true
        errorMessage = nil
        eventCreatedSuccessfully = false

        guard !title.isEmpty else {
            errorMessage = "El título del evento no puede estar vacío."
            isLoading = false
            return
        }

        guard startDate <= endDate else {
            errorMessage = "La fecha de inicio no puede ser posterior a la fecha de fin."
            isLoading = false
            return
        }

        // Extract user IDs from selectedParticipants
        let participantIDs = selectedParticipants.map { $0.uid }

        let newEvent = Event(
            roomId: roomId,
            title: title,
            description: description,
            startDate: startDate,
            endDate: endDate,
            participants: participantIDs,
            customColor: customColor
        )

        do {
            _ = try await EventService.shared.createEvent(event: newEvent, inRoomId: roomId)
            eventCreatedSuccessfully = true
        } catch {
            errorMessage = "Error al crear el evento: \(error.localizedDescription)"
        }
        isLoading = false
    }
}
