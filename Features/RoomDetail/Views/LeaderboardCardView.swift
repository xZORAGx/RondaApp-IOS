// Fichero: RondaApp/Features/RoomDetail/Views/LeaderboardCardView.swift

import SwiftUI

// ✅ El fichero completo y corregido
struct LeaderboardCardView: View {
    
    let rank: Int
    let entry: LeaderboardEntry
    let allDrinksInRoom: [Drink]

    // Colores dinámicos según el ranking
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray.opacity(0.8)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .blue
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // --- SECCIÓN SUPERIOR: USUARIO Y PUNTUACIÓN TOTAL ---
            HStack(spacing: 12) {
                rankCircle
                profileImage
                
                Text(entry.user.username ?? "Usuario")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                scoreView
            }
            
            // --- SECCIÓN INFERIOR: CONTADORES DE BEBIDAS ---
            drinkCounters
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.8))
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }
    
    // MARK: - Subviews para un código más limpio y mejor alineación

    private var rankCircle: some View {
        Text("\(rank)")
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 40, height: 40)
            .background(rankColor.opacity(0.8))
            .clipShape(Circle())
            .shadow(color: rankColor, radius: 5)
    }

    private var profileImage: some View {
        AsyncImage(url: URL(string: entry.user.photoURL ?? "")) { phase in
            if let image = phase.image {
                image.resizable().aspectRatio(contentMode: .fill)
            } else {
                Image(systemName: "person.fill")
                    .font(.title)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(width: 50, height: 50)
        .background(.black.opacity(0.2))
        .clipShape(Circle())
    }
    
    private var scoreView: some View {
        VStack {
            Text("\(entry.score)")
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            Text("pts")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 60) // Le damos un ancho fijo para estabilizar el layout
    }
    
    private var drinkCounters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 15) {
                ForEach(allDrinksInRoom) { drink in
                    HStack(spacing: 5) {
                        Text(drink.emoji ?? "🥤")
                            .font(.title3)
                        Text("\(entry.userScores[drink.id] ?? 0)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white) // Aseguramos color blanco
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(.black.opacity(0.25))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 50)
        .padding(.leading, 52) // Alinea el inicio de los contadores con el nombre
    }
}
