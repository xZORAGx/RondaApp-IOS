// Fichero: RondaApp/Features/RoomDetail/Views/LeaderboardCardView.swift

import SwiftUI

struct LeaderboardCardView: View {
    
    let rank: Int
    let entry: LeaderboardEntry // Usamos el modelo que combina usuario y puntuación

    var body: some View {
        HStack(spacing: 16) {
            // Posición en el ranking
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .frame(width: 30)

            // Foto de perfil del usuario
            AsyncImage(url: URL(string: entry.user.photoURL ?? "")) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .failure:
                    // Placeholder si no hay foto o falla la carga
                    Image(systemName: "person.fill")
                        .font(.title)
                        .foregroundColor(.white.opacity(0.7))
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.3))
            .clipShape(Circle())

            // Nombre de usuario
            Text(entry.user.username ?? "Usuario")
                .font(.headline)
                .foregroundColor(.white)

            Spacer()

            // Puntuación
            Text("\(entry.score)")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}


