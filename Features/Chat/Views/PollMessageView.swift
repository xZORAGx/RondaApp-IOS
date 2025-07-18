// Fichero: RondaApp/Features/Chat/Views/PollMessageView.swift

import SwiftUI

struct PollMessageView: View {
    let poll: Poll
    // El duel se pasa para saber quién es el retador y el oponente
    let duel: Duel
    @ObservedObject var viewModel: ChatViewModel
    
    // Helper para saber si el usuario actual ya ha votado
    private var currentUserVote: String? {
        for (option, voters) in poll.votes {
            if voters.contains(viewModel.user.uid) {
                return option
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(poll.question)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                // Las opciones de voto son los IDs de los jugadores y "draw"
                VoteOptionView(optionId: duel.challengerId, poll: poll, currentUserVote: currentUserVote, viewModel: viewModel)
                VoteOptionView(optionId: duel.opponentId, poll: poll, currentUserVote: currentUserVote, viewModel: viewModel)
                VoteOptionView(optionId: "draw", poll: poll, currentUserVote: currentUserVote, viewModel: viewModel)
            }
        }
        .padding(4)
    }
}

// Vista para una sola opción de voto con su barra de progreso
struct VoteOptionView: View {
    let optionId: String
    let poll: Poll
    let currentUserVote: String?
    @ObservedObject var viewModel: ChatViewModel

    private var voteCount: Int {
        poll.votes[optionId]?.count ?? 0
    }
    
    private var votePercentage: Double {
        // Usamos el total de miembros al crear la encuesta para una barra de progreso más estable
        let totalMembers = poll.memberCountAtCreation
        return totalMembers > 0 ? Double(voteCount) / Double(totalMembers) : 0
    }
    
    private var optionText: String {
        if optionId == "draw" { return "Empate" }
        return viewModel.memberProfiles[optionId]?.username ?? "Jugador"
    }
    
    private var hasVotedForThis: Bool {
        currentUserVote == optionId
    }

    var body: some View {
        Button(action: {
            if currentUserVote == nil { // Solo se puede votar si aún no lo has hecho
                Task { await viewModel.castVote(on: poll, for: optionId) }
            }
        }) {
            ZStack(alignment: .leading) {
                GeometryReader { geometry in
                    Capsule().fill(Color.white.opacity(0.1))
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: geometry.size.width * votePercentage)
                        .animation(.spring(), value: votePercentage)
                }
                
                HStack {
                    if hasVotedForThis {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    Text(optionText)
                        .fontWeight(hasVotedForThis ? .bold : .regular)
                    Spacer()
                    Text("\(voteCount)")
                        .fontWeight(.semibold)
                }
                .padding(.horizontal)
            }
            .frame(height: 40)
            .foregroundColor(.white)
        }
        .disabled(currentUserVote != nil)
        .overlay(
            // Añadimos un borde si el usuario ha votado por esta opción
            Capsule().stroke(Color.white, lineWidth: hasVotedForThis ? 2 : 0)
        )
    }
}
