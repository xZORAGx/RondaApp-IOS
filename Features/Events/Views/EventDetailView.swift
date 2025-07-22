
//
//  EventDetailView.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import SwiftUI

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel
    @State private var showingRewind = false

    init(eventId: String, roomId: String) {
        _viewModel = StateObject(wrappedValue: EventDetailViewModel(eventId: eventId, roomId: roomId))
    }

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Cargando evento...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            } else if let event = viewModel.event {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(event.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: event.customColor) ?? .accentColor)

                        Text(event.description)
                            .font(.body)
                            .foregroundColor(.secondary)

                        HStack {
                            Image(systemName: "calendar")
                            Text("\(event.startDate, formatter: dateFormatter) - \(event.endDate, formatter: dateFormatter)")
                        }
                        .font(.subheadline)
                        .foregroundColor(.gray)

                        // Countdown or Event Status
                        if event.isActive {
                            Text("Evento Activo")
                                .font(.headline)
                                .foregroundColor(.green)
                        } else {
                            Text("Evento Finalizado")
                                .font(.headline)
                                .foregroundColor(.red)
                        }

                        Divider()

                        Text("Clasificación del Evento")
                            .font(.title2)
                            .fontWeight(.semibold)

                        if viewModel.leaderboard.isEmpty {
                            Text("Nadie ha bebido aún en este evento.")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(viewModel.leaderboard) { scoreEntry in
                                HStack {
                                    Text(scoreEntry.username)
                                    Spacer()
                                    Text("\(scoreEntry.score) bebidas")
                                }
                                .padding(.vertical, 2)
                            }
                        }

                        if !event.isActive {
                            Button("Generar Rewind") {
                                showingRewind = true
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color(hex: event.customColor) ?? .accentColor)
                            .controlSize(.large)
                            .frame(maxWidth: .infinity)
                            .padding(.top)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(viewModel.event?.title ?? "Detalle del Evento")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingRewind) {
            // Pass the event ID and current user ID to RewindView
            // You'll need to get the current user ID from your SessionManager or similar
            RewindView(eventId: viewModel.event?.id ?? "", currentUserId: "dummyUserId", roomId: viewModel.event?.roomId ?? "")
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

struct EventDetailView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a dummy event for preview
        let dummyEvent = Event(
            id: "123",
            roomId: "dummyRoomId", // Added roomId
            title: "Fiesta del Pilar 2025",
            description: "Competición de bebidas durante las fiestas.",
            startDate: Date().addingTimeInterval(-3600 * 24 * 2), // 2 days ago
            endDate: Date().addingTimeInterval(3600 * 24 * 5),  // 5 days from now
            participants: ["user1", "user2", "user3"],
            customColor: "#FF5733",
            drinksConsumed: [
                EventDrinkEntry(userId: "user1", drinkId: "cerveza", timestamp: Date()),
                EventDrinkEntry(userId: "user2", drinkId: "vino", timestamp: Date()),
                EventDrinkEntry(userId: "user1", drinkId: "cerveza", timestamp: Date()),
                EventDrinkEntry(userId: "user3", drinkId: "agua", timestamp: Date())
            ]
        )
        
        // You might need to mock EventService.shared.fetchEvent for a proper preview
        // For simplicity, this preview will just show the UI structure.
        EventDetailView(eventId: dummyEvent.id!, roomId: dummyEvent.roomId)
    }
}
