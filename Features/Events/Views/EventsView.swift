// Fichero: RondaApp/Features/Events/Views/EventsView.swift (Final y Actualizado)

import SwiftUI

struct EventsView: View {
    @StateObject var viewModel: EventsViewModel
    @State private var showingCreateEventSheet = false
    let roomId: String

    init(roomId: String) {
        self.roomId = roomId
        _viewModel = StateObject(wrappedValue: EventsViewModel(roomId: roomId))
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                RadialGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.3), .black]),
                    center: .top, startRadius: 50, endRadius: 600
                ).ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Eventos")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal)
                        .padding(.top, 5)

                    ScrollView {
                        VStack(spacing: 20) {
                            if viewModel.isLoading {
                                ProgressView("Cargando eventos...")
                                    .tint(.white)
                                    .padding(.top, 50)
                            } else if viewModel.events.isEmpty {
                                ContentUnavailableView("No hay eventos", systemImage: "calendar.badge.plus", description: Text("Crea tu primer evento para empezar a competir."))
                                    .colorScheme(.dark)
                            } else {
                                CalendarView(events: viewModel.events.map { $0.event })
                                    .padding(.horizontal)

                                Text("Tus eventos")
                                    .font(.title2.bold())
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)

                                ForEach(viewModel.events) { eventDisplayData in
                                    NavigationLink(destination: EventDetailView(eventId: eventDisplayData.event.id!, roomId: roomId)) {
                                        EventCardView(event: eventDisplayData.event, participantUsers: eventDisplayData.participantUsers)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top, 20)
                    }
                }
                .navigationBarHidden(true)
            }
            .sheet(isPresented: $showingCreateEventSheet) {
                CreateEventView(roomId: roomId)
            }
            .overlay(alignment: .topTrailing) {
                Button {
                    showingCreateEventSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.purple)
                        .background(Circle().fill(.black))
                }
                .padding()
            }
        }
    }
}

struct EventCardView: View {
    let event: Event
    let participantUsers: [User]
    
    private var eventColor: Color {
        Color(hex: event.customColor) ?? .purple
    }
    
    private var cardDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        formatter.locale = Locale(identifier: "es_ES")
        return formatter
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    Text(cardDateFormatter.string(from: event.startDate))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(eventColor)
                }
                Spacer()
                if event.isActive {
                    Image(systemName: "flame.fill")
                        .foregroundColor(eventColor)
                        .padding(8)
                        .background(.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            HStack {
                ForEach(participantUsers.prefix(5)) { user in
                    UserAvatarView(user: user, size: 30)
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .padding(.leading, -12)
                }
                if event.participants.count > 5 {
                    Text("+\(event.participants.count - 5)")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.white.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.black, lineWidth: 2))
                        .padding(.leading, -12)
                }
                Spacer()
                Text("\(event.participants.count) participante\(event.participants.count == 1 ? "" : "s")")
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.gray)
            }
            .padding(.leading, 12)
        }
        .padding()
        .background(.white.opacity(0.05))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

struct EventsView_Previews: PreviewProvider {
    static var previews: some View {
        EventsView(roomId: "previewRoomId")
            .preferredColorScheme(.dark)
    }
}
