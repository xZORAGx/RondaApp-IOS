//
//  EventsView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

// Fichero: RondaApp/Features/RoomDetail/Views/Tabs/EventsView.swift

import SwiftUI

struct EventsView: View {
    var body: some View {
        ZStack {
            RadialGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0, blue: 0.2), .black]),
                center: .center,
                startRadius: 200,
                endRadius: 700
            )
            .ignoresSafeArea()
            
            VStack {
                Image(systemName: "calendar")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Text("Pantalla de Eventos")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                Text("Los eventos especiales con contadores aparecerán aquí.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    EventsView()
}
