
//
//  RewindView.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import SwiftUI
// import Lottie // Uncomment if you have Lottie integrated

struct RewindView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: RewindViewModel
    @State private var currentPage: Int = 0

    let pages: [RewindPageType]

    init(eventId: String, currentUserId: String, roomId: String) {
        _viewModel = StateObject(wrappedValue: RewindViewModel(eventId: eventId, currentUserId: currentUserId, roomId: roomId))
        self.pages = [
            .cover,
            .groupStats,
            .podium,
            .personalSummary,
            .share
        ]
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background color or gradient for the Rewind
                LinearGradient(gradient: Gradient(colors: [Color.purple.opacity(0.8), Color.blue.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()

                if viewModel.isLoading {
                    ProgressView("Generando Rewind...")
                        .foregroundColor(.white)
                } else if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                } else if let event = viewModel.event {
                    TabView(selection: $currentPage) {
                        ForEach(pages.indices, id: \.self) { index in
                            rewindPage(for: pages[index], event: event)
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Rewind")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cerrar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }

    @ViewBuilder
    private func rewindPage(for type: RewindPageType, event: Event) -> some View {
        VStack {
            Spacer()
            switch type {
            case .cover:
                RewindCoverPage(event: event)
            case .groupStats:
                RewindGroupStatsPage(totalDrinks: viewModel.totalDrinks, mostPopularDrink: viewModel.mostPopularDrink)
            case .podium:
                RewindPodiumPage(topPlayers: viewModel.topPlayers)
            case .personalSummary:
                RewindPersonalSummaryPage(personalSummary: viewModel.personalSummary)
            case .share:
                RewindSharePage(event: event) {
                    viewModel.shareRewind()
                }
            }
            Spacer()
        }
    }
}

enum RewindPageType {
    case cover
    case groupStats
    case podium
    case personalSummary
    case share
}

struct RewindCoverPage: View {
    let event: Event

    var body: some View {
        VStack {
            // Lottie Animation Placeholder
            // LottieView(animation: .named("confetti"))
            //     .loopMode(.playOnce)
            //     .frame(width: 200, height: 200)

            Text("¡El Rewind de")
                .font(.largeTitle)
                .foregroundColor(.white)

            Text(event.title)
                .font(.largeTitle)
                .fontWeight(.heavy)
                .foregroundColor(Color(hex: event.customColor) ?? .yellow)
                .multilineTextAlignment(.center)

            Text("ha llegado!")
                .font(.largeTitle)
                .foregroundColor(.white)
        }
    }
}

struct RewindGroupStatsPage: View {
    let totalDrinks: Int
    let mostPopularDrink: (drinkId: String, count: Int)?

    var body: some View {
        VStack(spacing: 20) {
            Text("Estadísticas del Grupo")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            RewindStatCard(title: "Total de Bebidas", value: "\(totalDrinks)", icon: "cup.and.saucer.fill")

            if let popularDrink = mostPopularDrink {
                RewindStatCard(title: "Bebida Estrella", value: popularDrink.drinkId.capitalized, icon: "star.fill")
            }
        }
        .padding()
    }
}

struct RewindPodiumPage: View {
    let topPlayers: [PlayerScore]

    var body: some View {
        VStack(spacing: 20) {
            Text("El Podio")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if topPlayers.isEmpty {
                Text("Nadie en el podio aún.")
                    .foregroundColor(.white.opacity(0.8))
            } else {
                ForEach(topPlayers) { player in
                    HStack {
                        Text("\(topPlayers.firstIndex(where: { $0.id == player.id })! + 1).")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        UserAvatarView(user: User(uid: player.userId, email: nil, photoURL: nil, username: player.username), size: 40)
                        Text(player.username)
                            .font(.title2)
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(player.count) bebidas")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}

struct RewindPersonalSummaryPage: View {
    let personalSummary: (userId: String, drinkId: String, count: Int)?

    var body: some View {
        VStack(spacing: 20) {
            Text("Tu Resumen Personal")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)

            if let summary = personalSummary {
                RewindStatCard(title: "Tu Bebida Favorita", value: summary.drinkId.capitalized, icon: "heart.fill")
                RewindStatCard(title: "Total Consumido", value: "\(summary.count)", icon: "chart.bar.fill")
            } else {
                Text("No hay datos personales para este evento.")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
    }
}

struct RewindSharePage: View {
    let event: Event
    let onShare: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Text("¡Comparte tu experiencia!")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Placeholder for shareable image/video preview
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.2))
                .frame(width: 250, height: 250)
                .overlay(
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.white.opacity(0.6))
                )

            Button {
                onShare()
            } label: {
                Label("Compartir Rewind", systemImage: "square.and.arrow.up.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .foregroundColor(Color(hex: event.customColor) ?? .accentColor)
                    .cornerRadius(15)
            }
            .padding(.horizontal, 40)
        }
    }
}

struct RewindStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.9))
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.15))
        .cornerRadius(15)
    }
}

struct RewindView_Previews: PreviewProvider {
    static var previews: some View {
        RewindView(eventId: "dummyEventId", currentUserId: "dummyUserId", roomId: "dummyRoomId")
    }
}
