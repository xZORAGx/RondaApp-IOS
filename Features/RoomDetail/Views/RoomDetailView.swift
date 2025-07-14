// Fichero: RoomDetailView.swift

import SwiftUI

struct RoomDetailView: View {
    
    // MARK: - Properties
    @StateObject private var viewModel: RoomDetailViewModel
    private let user: User
    
    enum ActiveSheet: Identifiable {
        case invite, drinks, adminPanel
        var id: Self { self }
    }
    
    @State private var activeSheet: ActiveSheet?
    
    init(room: Room, user: User) {
        self.user = user
        _viewModel = StateObject(wrappedValue: RoomDetailViewModel(room: room, user: user))
        
        // Personalización de la apariencia de la TabBar para que encaje con el estilo
        UITabBar.appearance().backgroundColor = UIColor.black.withAlphaComponent(0.9)
        UITabBar.appearance().barTintColor = .black
        UITabBar.appearance().unselectedItemTintColor = .gray
    }
    
    // MARK: - Body
    var body: some View {
        // El TabView es ahora el contenedor principal
        TabView {
            // Pestaña 1: La clasificación que ya teníamos
            leaderboardTab
                .tabItem {
                    Label("Clasificación", systemImage: "trophy.fill")
                }

            // Pestaña 2: Logros
            AchievementsView()
                .tabItem {
                    Label("Logros", systemImage: "star.fill")
                }

            // Pestaña 3: Chat
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            // Pestaña 4: Mapa
            MapView()
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }

            // Pestaña 5: Eventos
            EventsView()
                .tabItem {
                    Label("Eventos", systemImage: "calendar")
                }
        }
        // Los modificadores de navegación y la hoja modal se aplican al TabView
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
            // El contenido de la hoja modal no cambia
            switch sheet {
            case .invite:
                if let code = viewModel.room.invitationCode {
                    InvitationCodeView(roomTitle: viewModel.room.title, invitationCode: code)
                }
            case .drinks:
                DrinkSelectionView(
                    drinks: viewModel.room.drinks,
                    onSelectDrink: { selectedDrink in
                        viewModel.add(drink: selectedDrink)
                        activeSheet = nil
                    }
                )
                .presentationDetents([.medium, .large])
            case .adminPanel:
                AdminPanelView(viewModel: viewModel)
            }
        }
        .accentColor(.purple) // El color para el icono de la pestaña seleccionada
    }
    
    // MARK: - Subviews
    
    /// La vista de la primera pestaña, que contiene la clasificación y los botones de acción.
    private var leaderboardTab: some View {
        ZStack(alignment: .bottomTrailing) {
            RadialGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0, blue: 0.2), .black]),
                center: .bottom,
                startRadius: 200,
                endRadius: 800
            )
            .ignoresSafeArea()
            
            leaderboardList
            
            actionButtons
                .padding()
                .padding(.bottom, 40) // Espacio extra para que no se solape con la TabBar
        }
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
                }
            }
            .padding()
            .padding(.bottom, 120) // Aumentamos el padding inferior para dejar espacio a los botones y la TabBar
        }
    }
    
    private var actionButtons: some View {
        HStack {
            if viewModel.isUserAdmin {
                adminPanelButton
            }
            addDrinkButton
        }
    }
    
    private var adminPanelButton: some View {
        Button(action: { activeSheet = .adminPanel }) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle().fill(Color.yellow)
                        .shadow(color: .yellow.opacity(0.7), radius: 10, y: 5)
                )
        }
    }
    
    private var addDrinkButton: some View {
        Button(action: { activeSheet = .drinks }) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(
                    Circle().fill(Color.blue)
                        .shadow(color: .blue.opacity(0.7), radius: 10, y: 5)
                )
        }
    }
}
