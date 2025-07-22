// Fichero: RondaApp/Features/Events/ViewModels/EventsViewModel.swift

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
    @Published var isLoading = true
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let roomId: String

    init(roomId: String) {
        self.roomId = roomId
        setupEventSubscription()
    }

    private func setupEventSubscription() {
        EventService.shared.eventsPublisher(forRoomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Error al cargar eventos: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] fetchedEvents in
                guard let self = self else { return }
                
                Task {
                    var eventsDisplayData: [EventDisplayData] = []
                    for event in fetchedEvents {
                        do {
                            let participantUsers = try await UserService.shared.fetchUsers(withIDs: event.participants)
                            eventsDisplayData.append(EventDisplayData(id: event.id!, event: event, participantUsers: participantUsers))
                        } catch {
                            print("Error fetching participants for event \(event.id ?? "unknown"): \(error.localizedDescription)")
                            eventsDisplayData.append(EventDisplayData(id: event.id!, event: event, participantUsers: []))
                        }
                    }
                    
                    self.events = eventsDisplayData.sorted { $0.event.startDate < $1.event.startDate }
                    
                    if self.isLoading {
                        self.isLoading = false
                    }
                }
            })
            .store(in: &cancellables)
    }
}
