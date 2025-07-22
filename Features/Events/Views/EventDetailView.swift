// Fichero: RondaApp/Features/Events/Views/EventDetailView.swift (Versión Final y Rediseñada)

import SwiftUI

struct EventDetailView: View {
    @StateObject var viewModel: EventDetailViewModel
    @State private var showingRewind = false

    init(eventId: String, roomId: String) {
        _viewModel = StateObject(wrappedValue: EventDetailViewModel(eventId: eventId, roomId: roomId))
    }

    var body: some View {
        ZStack {
            // ✅ Nuevo fondo negro
            Color.black.ignoresSafeArea()
            
            // ✅ Gradiente sutil para un toque más dinámico
            RadialGradient(
                gradient: Gradient(colors: [Color.purple.opacity(0.3), .black]),
                center: .top, startRadius: 50, endRadius: 600
            ).ignoresSafeArea()
            
            VStack {
                if viewModel.isLoading {
                    ProgressView("Cargando evento...")
                        .tint(.white)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if let event = viewModel.event {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // --- Cabecera del Evento ---
                            eventHeader(event: event)
                            
                            Divider().background(Color.purple.opacity(0.5))

                            // --- Clasificación ---
                            Text("Clasificación")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            if viewModel.leaderboard.isEmpty {
                                Text("Nadie ha bebido aún en este evento.")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                // Usamos la nueva vista de fila personalizada
                                ForEach(Array(viewModel.leaderboard.enumerated()), id: \.element.id) { index, entry in
                                    EventLeaderboardRowView(
                                        rank: index + 1,
                                        entry: entry,
                                        allDrinksInRoom: viewModel.allDrinksInRoom,
                                        eventColor: Color(hex: event.customColor) ?? .purple
                                    )
                                }
                            }
                            
                            // --- Botón de Rewind ---
                            if !event.isActive {
                                rewindButton(event: event)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle(viewModel.event?.title ?? "Detalle del Evento")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingRewind) {
            RewindView(eventId: viewModel.event?.id ?? "", currentUserId: "dummyUserId", roomId: viewModel.event?.roomId ?? "")
        }
    }
    
    // --- Subvistas para organizar el código ---
    
    @ViewBuilder
    private func eventHeader(event: Event) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(event.title)
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            
            if !event.description.isEmpty {
                Text(event.description)
                    .font(.body)
                    .foregroundColor(.gray)
            }

            HStack {
                Image(systemName: "calendar")
                Text("\(event.startDate, style: .date) - \(event.endDate, style: .date)")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundColor(.purple)
        }
    }
    
    @ViewBuilder
    private func rewindButton(event: Event) -> some View {
        Button("Generar Rewind") {
            showingRewind = true
        }
        .font(.headline.bold())
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(hex: event.customColor) ?? .purple)
        .foregroundColor(.white)
        .cornerRadius(15)
        .padding(.top)
    }
}


// ✅ NUEVA VISTA PERSONALIZADA PARA CADA FILA DE LA CLASIFICACIÓN
struct EventLeaderboardRowView: View {
    let rank: Int
    let entry: EventLeaderboardEntry
    let allDrinksInRoom: [Drink]
    let eventColor: Color

    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.8)
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // --- Ranking ---
            Group {
                if rank == 1 {
                    Image(systemName: "crown.fill")
                } else {
                    Text("\(rank)")
                }
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(rankColor)
            .frame(width: 40)

            // --- Avatar (usa tu vista real) ---
            UserAvatarView(user: entry.user, size: 50)
            
            // --- Info del Usuario y Bebidas ---
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.user.username ?? "Usuario")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                
                // Lógica para el desglose de bebidas
                drinkCounters
            }
            
            Spacer()
            
            // --- Total de Bebidas ---
            VStack {
                Text("\(entry.totalDrinks)")
                    .font(.title2.bold().monospacedDigit())
                    .foregroundColor(eventColor)
                Text("total")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .frame(width: 60)
        }
        .padding(12)
        .background(.white.opacity(0.05))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }

    // Subvista para mostrar los contadores de bebidas
    private var drinkCounters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // Ordenamos para que las bebidas más consumidas aparezcan primero
                let sortedDrinkCounts = entry.drinkCounts.sorted { $0.value > $1.value }
                
                ForEach(sortedDrinkCounts, id: \.key) { drinkId, count in
                    if let drink = allDrinksInRoom.first(where: { $0.id == drinkId }) {
                        HStack(spacing: 4) {
                            Text(drink.emoji ?? "🥤")
                            Text("\(count)")
                                .font(.footnote.bold())
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .frame(height: 20)
    }
}

