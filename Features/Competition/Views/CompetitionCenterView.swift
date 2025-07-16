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
            // Próximamente...
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

struct BetsView: View {
    @ObservedObject var viewModel: RoomDetailViewModel
    @State private var wagerAmountString: String = ""

    var body: some View {
        ScrollView {
            // ✅ CAMBIO CLAVE: Se itera sobre viewModel.bets
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

struct DuelsView: View {
    @ObservedObject var viewModel: RoomDetailViewModel
    var body: some View {
        ScrollView {
            Text("Lista de Duelos Activos (Próximamente)").foregroundColor(.white).padding()
        }
    }
}
