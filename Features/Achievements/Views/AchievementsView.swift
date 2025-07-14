//
//  AchievementsView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

// Fichero: RondaApp/Features/RoomDetail/Views/Tabs/AchievementsView.swift

import SwiftUI

struct AchievementsView: View {
    var body: some View {
        ZStack {
            // Un fondo oscuro coherente con el resto de la app
            RadialGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0, blue: 0.2), .black]),
                center: .center,
                startRadius: 200,
                endRadius: 700
            )
            .ignoresSafeArea()
            
            VStack {
                Image(systemName: "star.fill")
                    .font(.largeTitle)
                    .foregroundColor(.yellow)
                Text("Pantalla de Logros")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                Text("Aquí se mostrarán los logros del grupo.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    AchievementsView()
}
