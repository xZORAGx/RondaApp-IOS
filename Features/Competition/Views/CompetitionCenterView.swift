// Fichero: RondaApp/Features/Competition/Views/CompetitionCenterView.swift

import SwiftUI

struct CompetitionCenterView: View {
    
    enum CompetitionTab {
        case bets, duels
    }
    
    @ObservedObject var viewModel: RoomDetailViewModel
    @State private var selectedTab: CompetitionTab = .bets
    @State private var isCreatingBet = false
    @State private var isCreatingDuel = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RadialGradient(
                gradient: Gradient(colors: [Color(red: 0.1, green: 0.1, blue: 0.2), .black]),
                center: .top,
                startRadius: 5,
                endRadius: 800
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Picker("Competición", selection: $selectedTab) {
                    Text("Apuestas").tag(CompetitionTab.bets)
                    Text("Duelos").tag(CompetitionTab.duels)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)

                HStack {
                    Spacer()
                    Label("\(viewModel.currentUserCredits)", systemImage: "dollarsign.circle.fill")
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.3))
                        .cornerRadius(20)
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                switch selectedTab {
                case .bets:
                    BetsView(viewModel: viewModel)
                case .duels:
                    DuelsView(viewModel: viewModel)
                }
                
                Spacer()
            }
            
            creationButton
                .padding()
                .padding(.bottom, 60)
        }
        .sheet(isPresented: $isCreatingBet) {
            CreateBetView(viewModel: viewModel)
        }
        .sheet(isPresented: $isCreatingDuel) {
            CreateDuelView(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    private var creationButton: some View {
        Button(action: {
            if selectedTab == .bets {
                isCreatingBet = true
            } else {
                isCreatingDuel = true
            }
        }) {
            Image(systemName: "plus")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 60, height: 60)
                .background(Circle().fill(Color.purple).shadow(color: .purple.opacity(0.7), radius: 10, y: 5))
        }
    }
}

// --- Vista para la lista de Apuestas (sin cambios) ---
struct BetsView: View {
    @ObservedObject var viewModel: RoomDetailViewModel
    @State private var wagerAmountString: String = ""

    var body: some View {
        ScrollView {
            if viewModel.bets.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.bets) { bet in
                        BetCardView(bet: bet, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
        .alert("Hacer Apuesta", isPresented: Binding(
            get: { viewModel.betToWagerOn != nil },
            set: { if !$0 { viewModel.betToWagerOn = nil } }
        ), actions: {
            TextField("Cantidad", text: $wagerAmountString)
                .keyboardType(.numberPad)
            Button("Apostar") {
                if let amount = Int(wagerAmountString), let bet = viewModel.betToWagerOn {
                    Task { await viewModel.placeWager(on: bet, amount: amount) }
                }
                wagerAmountString = ""
            }
            Button("Cancelar", role: .cancel) {
                wagerAmountString = ""
            }
        }, message: {
            if let bet = viewModel.betToWagerOn {
                Text("¿Cuántos créditos quieres apostar en \"\(bet.title)\"?\n\nTu saldo: \(viewModel.currentUserCredits) créditos.")
            }
        })
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "ticket.fill").font(.system(size: 50)).foregroundColor(.purple.opacity(0.6))
            Text("No hay apuestas activas").font(.title2).fontWeight(.bold)
            Text("¡Anímate a proponer la primera apuesta pulsando el botón '+'!").font(.subheadline).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .padding().padding(.top, 80)
    }
}


// --- ✅ VISTA PARA LA LISTA DE DUELOS (ACTUALIZADA CON .actionSheet) ---
struct DuelsView: View {
    @ObservedObject var viewModel: RoomDetailViewModel
    
    // Timer que se dispara cada 30 segundos para revisar los duelos.
    let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            if viewModel.duels.isEmpty {
                emptyStateView
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.duels) { duel in
                        DuelCardView(duel: duel, viewModel: viewModel)
                    }
                }
                .padding()
            }
        }
        .actionSheet(item: $viewModel.duelToResolve) { duel in
            createActionSheet(for: duel)
        }
        // ✅ CADA VEZ QUE EL TIMER SE DISPARA, LLAMAMOS A LA FUNCIÓN DE CHEQUEO
        .onReceive(timer) { _ in
            viewModel.checkForFinishedAdminDuels()
        }
        // También lo comprobamos una vez al cargar la vista.
        .onAppear {
            viewModel.checkForFinishedAdminDuels()
        }
    }
    
    private func createActionSheet(for duel: Duel) -> ActionSheet {
        let challengerName = viewModel.roomMembers.first { $0.uid == duel.challengerId }?.username ?? "Retador"
        let opponentName = viewModel.roomMembers.first { $0.uid == duel.opponentId }?.username ?? "Oponente"
        
        return ActionSheet(
            title: Text("¿Quién ganó el duelo?"),
            message: Text(duel.title),
            buttons: [
                .default(Text(challengerName)) {
                    Task { await viewModel.resolveDuelAsAdmin(duel: duel, winnerId: duel.challengerId) }
                },
                .default(Text(opponentName)) {
                    Task { await viewModel.resolveDuelAsAdmin(duel: duel, winnerId: duel.opponentId) }
                },
                .default(Text("Empate")) {
                    Task { await viewModel.resolveDuelAsAdmin(duel: duel, winnerId: nil) }
                },
                .cancel()
            ]
        )
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bolt.horizontal.fill")
                .font(.system(size: 50))
                .foregroundColor(.red.opacity(0.6))
            Text("No hay duelos activos")
                .font(.title2)
                .fontWeight(.bold)
            Text("¡Reta a alguien de la sala pulsando el botón '+'!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .padding(.top, 80)
    }
}
