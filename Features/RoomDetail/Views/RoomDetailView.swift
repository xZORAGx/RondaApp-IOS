// Fichero: RondaApp/Features/RoomDetail/Views/RoomDetailView.swift

import SwiftUI

struct RoomDetailView: View {
    
    @StateObject private var viewModel: RoomDetailViewModel
    private let user: User
    
    init(room: Room, user: User) {
        self.user = user
        _viewModel = StateObject(wrappedValue: RoomDetailViewModel(room: room, user: user))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Fondo oscuro con degradado
            LinearGradient(
                colors: [Color.black, Color(white: 0.15)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Contenido principal con las tarjetas de clasificación
            ScrollView {
                VStack(spacing: 12) {
                    // La vista ahora itera sobre la lista pre-procesada del ViewModel
                    ForEach(Array(viewModel.leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                        LeaderboardCardView(
                            rank: index + 1,
                            entry: entry
                        )
                    }
                }
                .padding()
            }
            
            // Botón de acción para añadir ronda
            addDrinkButton
                .padding()
        }
        .navigationTitle(viewModel.room.title)
        .navigationBarTitleDisplayMode(.inline)
        // Estilo de la barra de navegación para que se integre con el fondo oscuro
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private var addDrinkButton: some View {
        Button(action: viewModel.addDrink) {
            Label("Añadir Ronda", systemImage: "plus")
                .font(.headline)
                .fontWeight(.bold)
                .padding()
                .frame(maxWidth: .infinity)
                .background(.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
                .shadow(color: .blue.opacity(0.5), radius: 10, y: 5)
        }
    }
}

#Preview {
    // Creamos datos de ejemplo para la preview
    let previewUser = User(uid: "123", email: "test@test.com", username: "David", age: 25, hasAcceptedPolicy: true, hasCompletedProfile: true)
    let previewRoom = Room(id: "abc", title: "Sala de Fiesta", ownerId: "123", memberIds: ["123", "456"], scores: ["123": 15, "456": 8])
    
    // Envolvemos la vista en un NavigationView para que la preview sea realista
    return NavigationView {
        RoomDetailView(room: previewRoom, user: previewUser)
    }
} 
