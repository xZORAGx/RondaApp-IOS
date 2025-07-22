// Fichero: RondaApp/Features/RoomDetail/Views/RoomDetailView.swift
// ✅ VERSIÓN ACTUALIZADA CON LA PESTAÑA DE MAPA

import SwiftUI

struct RoomDetailView: View {
    
    // MARK: - ViewModels
    @StateObject private var viewModel: RoomDetailViewModel
    @StateObject private var chatViewModel: ChatViewModel
    
    // MARK: - Properties
    private let user: User
    @State private var activeSheet: ActiveSheet?
    @State private var hasNewNotifications = false
    
    enum ActiveSheet: Identifiable {
            case invite, adminPanel, addCheckIn // Cambiamos 'drinks' por 'addCheckIn'
            var id: Self { self }
        }
    
    // MARK: - Initializer
    init(room: Room, user: User) {
        self.user = user
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
            // Pestaña 1: Clasificación
            leaderboardTab
                .tabItem {
                    Label("Clasificación", systemImage: "trophy.fill")
                }

            // Pestaña 2: Centro de Competición
            CompetitionCenterView(viewModel: viewModel)
                .tabItem {
                    Label("Competición", systemImage: "gamecontroller.fill")
                }
                .badge(hasNewNotifications ? "!" : nil)

            // Pestaña 3: Chat
            ChatView(viewModel: chatViewModel)
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
            
            // ✅ PESTAÑA DE MAPA AÑADIDA DE VUELTA
            MapView(room: viewModel.room, members: viewModel.roomMembers)
                .tabItem {
                    Label("Mapa", systemImage: "map.fill")
                }
            
            // Pestaña 5: Eventos
            EventsView(roomId: viewModel.room.id ?? "")
                .tabItem {
                    Label("Eventos", systemImage: "calendar")
                }
        }
        .navigationTitle(viewModel.room.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
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
                   case .adminPanel:
                       AdminPanelView(viewModel: viewModel)
                   
                   // Aquí está la magia: presentamos la nueva vista
                   case .addCheckIn:
                       AddCheckInView(viewModel: viewModel)
                   }
               }
        .accentColor(.purple)
        .onReceive(viewModel.$room) { updatedRoom in
            let oldBetCount = viewModel.room.bets.count
            let newBetCount = updatedRoom.bets.count
            self.hasNewNotifications = newBetCount > oldBetCount
        }
    }
    
    // El resto del código de la vista (subviews) permanece igual...
    // MARK: - Subviews
    
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
                .padding(.bottom, 40)
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
            .padding(.bottom, 120)
        }
    }
    
    private var actionButtons: some View {
        HStack {
            if viewModel.isUserAdmin {
                adminPanelButton
            }
            // ✅ 3. RENOMBRAMOS EL BOTÓN Y ACTUALIZAMOS SU ACCIÓN
            addMomentButton // El botón ahora es para "momentos"
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
    

    
    private var addMomentButton: some View {
           Button(action: { activeSheet = .addCheckIn }) { // La acción ahora abre nuestra nueva vista
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

