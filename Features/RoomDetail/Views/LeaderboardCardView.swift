// Fichero: RondaApp/Features/RoomDetail/Views/LeaderboardCardView.swift

import SwiftUI

struct LeaderboardCardView: View {
    
    let rank: Int
    let entry: LeaderboardEntry
    let allDrinksInRoom: [Drink]

    // Colores para el podio
    var rankColor: Color {
        switch rank {
        case 1: return .yellow
        case 2: return .gray.opacity(0.8)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .accentColor // Usamos el color de acento de la app
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // --- Iconografía de Ranking (Corona o Número) ---
            rankView
            
            // Mantenemos la foto de perfil que ya tenías
            profileImage
            
            // --- Nombre de Usuario y Contadores de Bebidas ---
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.user.username ?? "Usuario")
                    .font(.headline)
                    .fontWeight(.bold) // Un poco más de peso para el nombre
                    .foregroundColor(.white)
                
                // Mantenemos los contadores de bebidas
                drinkCounters
            }
            
            Spacer()
            
            // --- Puntuación con Animación ---
            scoreView
        }
        .padding(12) // Un padding ligeramente más ajustado
        .background(.ultraThinMaterial.opacity(0.9)) // Mantenemos el fondo de cristal
        .cornerRadius(20)
        .overlay(
            // Mantenemos el borde para darle profundidad
            RoundedRectangle(cornerRadius: 20)
                .stroke(LinearGradient(colors: [.white.opacity(0.4), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1.5)
        )
        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
    }
    
    // MARK: - Subviews

    @ViewBuilder
    private var rankView: some View {
        // Lógica para mostrar corona o número
        Group {
            if rank == 1 {
                Image(systemName: "crown.fill")
                    .font(.title2)
            } else {
                Text("\(rank)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .foregroundColor(rankColor)
        .frame(width: 40)
        .shadow(color: rankColor, radius: 8) // Sombra para resaltar
    }
    
    // La vista de la imagen de perfil no cambia
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
            // ✅ SOLUCIÓN FINAL: Usamos nuestro nuevo componente encapsulado.
            AnimatedScoreView(score: entry.score)

            Text("pts")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: 65)
    }
    
    // La vista de los contadores de bebida no cambia
    private var drinkCounters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(allDrinksInRoom) { drink in
                    // Solo mostramos la bebida si el contador es mayor que 0
                    if let count = entry.userScores[drink.id], count > 0 {
                        HStack(spacing: 4) {
                            Text(drink.emoji ?? "🥤")
                            Text("\(count)")
                                .font(.footnote)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .frame(height: 20) // Un poco más compacto
    }
}
