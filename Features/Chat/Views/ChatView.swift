//
//  ChatView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

// Fichero: RondaApp/Features/RoomDetail/Views/Tabs/ChatView.swift

import SwiftUI

struct ChatView: View {
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
                Image(systemName: "message.fill")
                    .font(.largeTitle)
                    .foregroundColor(.blue)
                Text("Pantalla de Chat")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                Text("El chat en tiempo real para la sala estará aquí.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }
}

#Preview {
    ChatView()
}
