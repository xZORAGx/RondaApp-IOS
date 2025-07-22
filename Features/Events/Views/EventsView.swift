//
//  EventsView.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import SwiftUI

struct EventsView: View {
    @StateObject var viewModel: EventsViewModel
    @State private var showingCreateEventSheet = false

    let roomId: String // New property

    init(roomId: String) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: EventsViewModel(roomId: roomId))
    }

    var body: some View {
        NavigationView {
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando eventos...")
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if viewModel.events.isEmpty {
                    ContentUnavailableView("No hay eventos", systemImage: "calendar.badge.plus", description: Text("Crea tu primer evento para empezar a competir."))
                } else {
                    ScrollView {
                        CalendarView(events: viewModel.events.map { $0.event })
                            .padding(.bottom)

                        LazyVStack(spacing: 15) {
                            ForEach(viewModel.events) { eventDisplayData in
                                NavigationLink(destination: EventDetailView(eventId: eventDisplayData.event.id!, roomId: roomId)) {
                                    EventCardView(event: eventDisplayData.event, participantUsers: eventDisplayData.participantUsers)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Eventos")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateEventSheet = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingCreateEventSheet) {
                CreateEventView(roomId: roomId) // Use the actual roomId from the view
            }
        }
    }
}

struct EventCardView: View {
    let event: Event
    let participantUsers: [User]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(event.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            HStack {
                Image(systemName: "calendar")
                Text("\(event.startDate, formatter: dateFormatter) - \(event.endDate, formatter: dateFormatter)")
            }
            .font(.caption)
            .foregroundColor(.gray)

            HStack {
                Image(systemName: "flame.fill")
                Text("\(event.drinksConsumed.count) bebidas")
            }
            .font(.caption)
            .foregroundColor(.gray)

            // Progress Bar Placeholder (Conceptual)
            ProgressView(value: 0.5) // Replace with actual progress calculation
                .progressViewStyle(LinearProgressViewStyle(tint: Color(hex: event.customColor) ?? .accentColor))
                .scaleEffect(x: 1, y: 2, anchor: .center)
                .padding(.vertical, 5)

            HStack {
                ForEach(participantUsers.prefix(3)) { user in
                    UserAvatarView(user: user, size: 24)
                }
                if event.participants.count > 3 {
                    Text("+ \(event.participants.count - 3)")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}


private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .none
    return formatter
}()

// Extension to convert Hex String to Color
extension Color {
    init?(hex: String) {
        let r, g, b, a: Double

        let start = hex.hasPrefix("#") ? hex.index(hex.startIndex, offsetBy: 1) : hex.startIndex
        let hexColor = String(hex[start...])

        if hexColor.count == 6 {
            let scanner = Scanner(string: hexColor)
            var hexNumber: UInt64 = 0

            if scanner.scanHexInt64(&hexNumber) {
                r = Double((hexNumber & 0xff0000) >> 16) / 255
                g = Double((hexNumber & 0x00ff00) >> 8) / 255
                b = Double(hexNumber & 0x0000ff) / 255
                a = 1.0
                self.init(red: r, green: g, blue: b, opacity: a)
                return
            }
        }
        return nil
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView(roomId: "previewRoomId")
    }
}
