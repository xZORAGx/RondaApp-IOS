// Fichero: RondaApp/Features/RoomDetail/Views/RoomDetailView.swift

import SwiftUI

struct RoomDetailView: View {
    
    // MARK: - ViewModels
    @StateObject private var viewModel: RoomDetailViewModel
    // ✅ Declara el StateObject para el ViewModel del chat.
    @StateObject private var chatViewModel: ChatViewModel
    
    // MARK: - Properties
    private let user: User
    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case invite, drinks, adminPanel
        var id: Self { self }
    }
    
    // MARK: - Initializer
    init(room: Room, user: User) {
        self.user = user
        // ✅ Modificamos el 'init' para crear AMBOS ViewModels.
        _viewModel = StateObject(wrappedValue: RoomDetailViewModel(room: room, user: user))
        _chatViewModel = StateObject(wrappedValue: ChatViewModel(room: room, user: user))
        
        // Personalización de la TabBar
        UITabBar.appearance().backgroundColor = UIColor.black.withAlphaComponent(0.9)
        UITabBar.appearance().barTintColor = .black
        UITabBar.appearance().unselectedItemTintColor = .gray
    }
    
    // MARK: - Body
    var body: some View {
        TabView {
            // Pestaña de Clasificación
            ZStack(alignment: .bottomTrailing) {
                leaderboardTab
                actionButtons
            }
            .tabItem {
                Label("Clasificación", systemImage: "trophy.fill")
            }

            // Pestaña de Logros
            AchievementsView().tabItem { Label("Logros", systemImage: "star.fill") }

            // ✅ Inyectamos el chatViewModel en la ChatView.
            ChatView(viewModel: chatViewModel)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            // Otras pestañas
            MapView().tabItem { Label("Mapa", systemImage: "map.fill") }
            EventsView().tabItem { Label("Eventos", systemImage: "calendar") }
        }
        .navigationTitle(viewModel.room.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { activeSheet = .invite }) {
                    Image(systemName: "person.badge.plus")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .invite:
                if let code = viewModel.room.invitationCode {
                    InvitationCodeView(roomTitle: viewModel.room.title, invitationCode: code)
                }
            case .drinks:
                DrinkSelectionView(drinks: viewModel.room.drinks) { selectedDrink in
                    viewModel.add(drink: selectedDrink)
                    activeSheet = nil
                }
                .presentationDetents([.medium, .large])
            case .adminPanel:
                AdminPanelView(viewModel: viewModel)
            }
        }
        .accentColor(.purple)
    }
    
    // MARK: - Subviews
    
    private var leaderboardTab: some View {
        RadialGradient(
            gradient: Gradient(colors: [Color(red: 0.1, green: 0, blue: 0.2), .black]),
            center: .bottom,
            startRadius: 200,
            endRadius: 800
        )
        .ignoresSafeArea()
        .overlay(leaderboardList)
    }
    
    private var leaderboardList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(Array(viewModel.leaderboardEntries.enumerated()), id: \.element.id) { index, entry in
                    LeaderboardCardView(
                        rank: index + 1,
                        entry: entry,
                        allDrinksInRoom: viewModel.room.drinks
                    )
                    .transition(.move(edge: .leading).combined(with: .opacity))
                }
            }
            .padding()
            .padding(.bottom, 120)
        }
        .animation(.default, value: viewModel.leaderboardEntries)
    }
    
    private var actionButtons: some View {
        HStack {
            if viewModel.isUserAdmin {
                Button(action: { activeSheet = .adminPanel }) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 22, weight: .bold))
                }
                .buttonStyle(FloatingActionButtonStyle(backgroundColor: .gray))
            }
            
            Button(action: { activeSheet = .drinks }) {
                Image(systemName: "plus")
                    .font(.system(size: 28, weight: .bold))
            }
            .buttonStyle(FloatingActionButtonStyle(backgroundColor: .blue))
        }
        .padding()
        .padding(.bottom, 50)
    }
}

// Estilo reutilizable para los botones flotantes
struct FloatingActionButtonStyle: ButtonStyle {
    let backgroundColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(backgroundColor)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
            .scaleEffect(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
