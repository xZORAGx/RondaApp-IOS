
//
//  EventsViewModel.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import Foundation
import Combine

struct EventDisplayData: Identifiable {
    let id: String
    let event: Event
    var participantUsers: [User]
}

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [EventDisplayData] = []
    @Published var isLoading = true // Start with loading true
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let roomId: String

    init(roomId: String) {
        self.roomId = roomId
        setupEventSubscription()
    }

    private func setupEventSubscription() {
        EventService.shared.eventsPublisher(forRoomId: roomId)
            .receive(on: DispatchQueue.main) // Switch to main thread early
            .sink(receiveCompletion: { [weak self] completion in
                // This will only be called on error, since the listener doesn't complete.
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al cargar eventos: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] fetchedEvents in
                guard let self = self else { return }
                
                // Use a Task to perform async user fetching off the main thread
                Task {
                    var eventsDisplayData: [EventDisplayData] = []
                    for event in fetchedEvents {
                        do {
                            // Fetch users for each event
                            let participantUsers = try await UserService.shared.fetchUsers(withIDs: event.participants)
                            eventsDisplayData.append(EventDisplayData(id: event.id!, event: event, participantUsers: participantUsers))
                        } catch {
                            // If fetching users fails for one event, we still display the event
                            print("Error fetching participants for event \(event.id ?? "unknown"): \(error.localizedDescription)")
                            eventsDisplayData.append(EventDisplayData(id: event.id!, event: event, participantUsers: []))
                        }
                    }
                    
                    // Once all async work is done, update the UI on the main thread
                    // @MainActor ensures this runs on the main thread
                    self.events = eventsDisplayData.sorted { $0.event.startDate < $1.event.startDate }
                    
                    // The loading is finished after the first successful data load
                    if self.isLoading {
                        self.isLoading = false
                    }
                }
            })
            .store(in: &cancellables)
    }
}
