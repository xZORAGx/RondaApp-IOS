//
//  CreateDuelView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 17/7/25.
//

// Fichero: RondaApp/Features/Competition/Views/CreateDuelView.swift

import SwiftUI

struct CreateDuelView: View {
    
    @ObservedObject var viewModel: RoomDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Estados del formulario
    @State private var title: String = ""
    @State private var opponentId: String = ""
    @State private var wagerString: String = ""
    @State private var endDate: Date = Date().addingTimeInterval(86400) // 1 día por defecto
    
    // Propiedad para validar el formulario
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !opponentId.isEmpty &&
        (Int(wagerString) ?? 0) > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Detalles del Duelo") {
                    TextField("Título (Ej: Duelo de chupitos)", text: $title)
                    Picker("Oponente", selection: $opponentId) {
                        Text("Selecciona un jugador").tag("")
                        // Filtramos para no poder retarnos a nosotros mismos
                        ForEach(viewModel.roomMembers.filter { $0.uid != viewModel.currentUser?.uid }) { member in
                            Text(member.username ?? "Usuario").tag(member.uid)
                        }
                    }
                }
                
                Section("Apuesta y Duración") {
                    HStack {
                        Text("Créditos en juego (por jugador):")
                        Spacer()
                        TextField("0", text: $wagerString)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                    DatePicker("Finaliza el", selection: $endDate, displayedComponents: [.date, .hourAndMinute])
                }
                
                Section {
                    Button(action: createDuel) {
                        Text("Lanzar Reto")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Nuevo Duelo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    private func createDuel() {
        guard let wager = Int(wagerString),
              let challengerId = viewModel.currentUser?.uid else { return }
        
        let newDuel = Duel(
            title: title,
            challengerId: challengerId,
            opponentId: opponentId,
            wager: wager,
            startTime: .init(date: Date()),
            endTime: .init(date: endDate)
        )
        
        Task {
            let success = await viewModel.createDuel(newDuel)
            if success {
                dismiss()
            }
        }
    }
}
