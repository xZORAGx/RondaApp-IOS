// Fichero: RondaApp/Features/Competition/Views/DuelCardView.swift

import SwiftUI

struct DuelCardView: View {
    let duel: Duel
    let viewModel: RoomDetailViewModel
    
    // Estado para el contador y el timer
    @State private var countdownString: String = ""
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private func user(for userId: String) -> User? {
        return viewModel.roomMembers.first { $0.uid == userId }
    }
    
    // Helper para saber si el duelo ha terminado y está pendiente de resolución
    private var isDuelFinished: Bool {
        return duel.endTime.dateValue() < Date() && duel.status == .inProgress
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(duel.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Mostramos el contador si el duelo está en progreso
            if !countdownString.isEmpty {
                HStack {
                    Image(systemName: "timer")
                        .foregroundColor(.cyan)
                    Text("Finaliza en: \(countdownString)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.top, 4)
            }
            
            HStack {
                PlayerAvatarView(user: user(for: duel.challengerId))
                Spacer()
                Text("VS")
                    .font(.headline)
                    .fontWeight(.heavy)
                    .foregroundColor(.red)
                Spacer()
                PlayerAvatarView(user: user(for: duel.opponentId))
            }
            .padding(.vertical, 10)
            
            Divider().background(Color.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("EN JUEGO")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Label("\(duel.wager) créditos", systemImage: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("ESTADO")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(isDuelFinished ? "Finalizado" : duel.status.rawValue)
                        .foregroundColor(statusColor(for: duel.status))
                }
            }
            .font(.subheadline.bold())
            
            actionButtons
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.black.opacity(0.4)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(.purple.opacity(0.5), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }

    // ✅ VISTA DE BOTONES ACTUALIZADA CON LA LÓGICA DE ACEPTACIÓN
    @ViewBuilder
    private var actionButtons: some View {
        let isAdmin = viewModel.isUserAdmin
        let isAdminParticipant = duel.challengerId == viewModel.currentUser?.uid || duel.opponentId == viewModel.currentUser?.uid
        let isOpponent = viewModel.currentUser?.uid == duel.opponentId
        
        // --- Caso 1: El duelo está esperando aceptación ---
        if duel.status == .awaitingAcceptance {
            if isOpponent {
                HStack {
                    Button("Rechazar") {
                        Task { await viewModel.declineDuel(duel: duel) }
                    }.buttonStyle(BetButtonStyle(color: .red))
                    
                    Button("Aceptar Reto") {
                        Task { await viewModel.acceptDuel(duel: duel) }
                    }.buttonStyle(BetButtonStyle(color: .green))
                }
                .padding(.top, 5)
            }
        }
        // --- Caso 2: El duelo ha terminado y el admin puede resolverlo ---
        else if isDuelFinished && isAdmin && !isAdminParticipant {
            HStack {
                Button("Crear Encuesta") {
                    Task { await viewModel.startDuelPoll(for: duel) }
                }.buttonStyle(BetButtonStyle(color: .blue))
                
                Button("Decidir Ganador") {
                    viewModel.duelToResolve = duel
                }.buttonStyle(BetButtonStyle(color: .green))
            }
            .padding(.top, 5)
        }
    }
    
    private func statusColor(for status: DuelStatus) -> Color {
        switch status {
        case .awaitingAcceptance: return .orange
        case .inProgress: return .cyan
        case .inPoll: return .blue
        case .resolved: return .gray
        }
    }
    
    private func updateCountdown() {
        // El contador solo se muestra si el duelo ya ha sido aceptado
        guard duel.status == .inProgress else {
            countdownString = ""
            return
        }
        
        let remainingTime = duel.endTime.dateValue().timeIntervalSinceNow
        
        if remainingTime > 0 {
            let days = Int(remainingTime) / 86400
            let hours = (Int(remainingTime) % 86400) / 3600
            let minutes = (Int(remainingTime) % 3600) / 60
            let seconds = Int(remainingTime) % 60
            
            if days > 0 {
                countdownString = "\(days)d \(hours)h"
            } else {
                countdownString = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
            }
        } else {
            countdownString = ""
        }
    }
}

// Pequeña vista auxiliar para mostrar el avatar y nombre del jugador
struct PlayerAvatarView: View {
    let user: User?
    
    var body: some View {
        VStack {
            AsyncImage(url: URL(string: user?.photoURL ?? "")) { image in
                image.resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.fill")
                    .foregroundColor(.white.opacity(0.8))
            }
            .frame(width: 60, height: 60)
            .background(.black.opacity(0.3))
            .clipShape(Circle())
            
            Text(user?.username ?? "Jugador")
                .font(.headline)
                .foregroundColor(.white)
        }
    }
}
