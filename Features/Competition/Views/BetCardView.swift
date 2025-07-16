// Fichero: RondaApp/Features/Competition/Views/BetCardView.swift

import SwiftUI

struct BetCardView: View {
    
    let bet: Bet
    let viewModel: RoomDetailViewModel
    
    // Estado para el texto del contador
    @State private var countdownString: String = ""
    // Timer para actualizar la vista cada segundo
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private func username(for userId: String) -> String {
        viewModel.roomMembers.first { $0.uid == userId }?.username ?? "Un usuario"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(bet.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Divider().background(.white.opacity(0.2))
            
            HStack {
                VStack(alignment: .leading) {
                    Text("PROTAGONISTA")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Label(username(for: bet.targetUserId), systemImage: "person.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                Spacer()
                
                VStack {
                    Text("CUOTA")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    Text(String(format: "x%.2f", bet.odds))
                        .font(.title3)
                        .fontWeight(.heavy)
                        .foregroundColor(.purple)
                }
            }
            
            HStack {
                Label(bet.deadline.dateValue().formatted(date: .abbreviated, time: .shortened), systemImage: "calendar.badge.clock")
                Spacer()
                Text(bet.status.rawValue)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(bet.status).opacity(0.2))
                    .foregroundColor(statusColor(bet.status))
                    .cornerRadius(8)
            }
            .font(.footnote)
            .foregroundColor(.white.opacity(0.8))

            actionButtons
            
            if bet.status != .pending && !countdownString.isEmpty {
                HStack {
                    Image(systemName: "hourglass.bottomhalf.fill")
                    Text("Esta apuesta se eliminará en \(countdownString)")
                }
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.top, 5)
            }
        }
        .padding()
        .background(.black.opacity(0.3))
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
        .onReceive(timer) { _ in
            updateCountdown()
        }
        .onAppear {
            updateCountdown()
        }
    }
    
    // ✅ LÓGICA DE BOTONES CORREGIDA
    @ViewBuilder
    private var actionButtons: some View {
        // Solo mostramos botones si la apuesta está pendiente
        if bet.status == .pending {
            VStack(spacing: 12) {
                // --- Botón de Apostar (Para todos, si no han apostado) ---
                let hasWagered = bet.wagers[viewModel.currentUser?.uid ?? ""] != nil
                
                Button {
                    viewModel.betToWagerOn = bet
                } label: {
                    Label(hasWagered ? "Ya has apostado" : "Apostar créditos", systemImage: "dollarsign.circle.fill")
                }
                .buttonStyle(BetButtonStyle(color: .purple))
                .disabled(hasWagered)

                // --- Botones de Administrador (Solo para el admin) ---
                if viewModel.isUserAdmin {
                    HStack {
                        Button("Anular") { Task { await viewModel.resolveBet(bet: bet, newStatus: .cancelled) } }
                            .buttonStyle(BetButtonStyle(color: .gray))
                        
                        Button("Perdida") { Task { await viewModel.resolveBet(bet: bet, newStatus: .lost) } }
                            .buttonStyle(BetButtonStyle(color: .red))
                        
                        Button("Ganada") { Task { await viewModel.resolveBet(bet: bet, newStatus: .won) } }
                            .buttonStyle(BetButtonStyle(color: .green))
                    }
                }
            }
        }
    }
    
    private func statusColor(_ status: BetStatus) -> Color {
        switch status {
        case .pending: return .yellow
        case .won: return .green
        case .lost: return .red
        case .cancelled: return .gray
        }
    }
    
    private func updateCountdown() {
        guard let resolvedDate = bet.resolvedAt?.dateValue() else {
            countdownString = ""
            return
        }
        
        let expirationDate = resolvedDate
        let remainingTime = expirationDate.timeIntervalSince(Date())
        
        if remainingTime > 0 {
            let hours = Int(remainingTime) / 3600
            let minutes = (Int(remainingTime) % 3600) / 60
            let seconds = Int(remainingTime) % 60
            countdownString = String(format: "%02i:%02i:%02i", hours, minutes, seconds)
        } else {
            countdownString = "un instante..."
        }
    }
}

struct BetButtonStyle: ButtonStyle {
    let color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.bold())
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}
