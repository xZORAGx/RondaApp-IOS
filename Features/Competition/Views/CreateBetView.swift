//
//  CreateBetView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 16/7/25.
//

// Fichero: RondaApp/Features/Competition/Views/CreateBetView.swift

import SwiftUI

struct CreateBetView: View {
    
    @ObservedObject var viewModel: RoomDetailViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Estados para los campos del formulario
    @State private var title: String = ""
    @State private var targetUserId: String = ""
    @State private var deadline: Date = Date().addingTimeInterval(86400) // Mañana por defecto
    @State private var odds: Double = 1.5
    @State private var wagerString: String = ""

    // Propiedad para validar el formulario
    private var isFormValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty &&
        !targetUserId.isEmpty &&
        Int(wagerString) ?? 0 > 0
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("¿Qué va a pasar?") {
                    TextField("Ej: Carlos no llega a 10 cervezas", text: $title, axis: .vertical)
                        .lineLimit(3)
                }
                
                Section("Protagonista y Cuota") {
                    Picker("Jugador implicado", selection: $targetUserId) {
                        Text("Selecciona un jugador").tag("")
                        ForEach(viewModel.roomMembers) { member in
                            Text(member.username ?? "Usuario desconocido").tag(member.uid)
                        }
                    }
                    
                    Stepper("Cuota: \(odds, specifier: "%.2f")", value: $odds, in: 1.01...2.0, step: 0.05)
                }
                
                Section("Condiciones") {
                    DatePicker("Fecha límite", selection: $deadline, displayedComponents: [.date, .hourAndMinute])
                    
                    HStack {
                        Text("Mis créditos a apostar:")
                        Spacer()
                        TextField("0", text: $wagerString)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section {
                    Button(action: createBet) {
                        Text("Proponer Apuesta")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                }
            }
            .navigationTitle("Nueva Apuesta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                // Selecciona el primer miembro de la lista por defecto (si existe)
                if let firstMemberId = viewModel.roomMembers.first?.uid {
                    targetUserId = firstMemberId
                }
            }
        }
    }
    
    private func createBet() {
        guard let wager = Int(wagerString), let proposerId = viewModel.currentUser?.uid else { return }
        
        // Creamos el objeto Bet con los datos del formulario
        let newBet = Bet(
            title: title,
            targetUserId: targetUserId,
            proposerUserId: proposerId,
            odds: odds,
            deadline: .init(date: deadline),
            wagers: [proposerId: wager] // Añadimos la apuesta inicial del creador
        )
        
        Task {
            // Llamamos a la función del ViewModel
            let success = await viewModel.createBet(newBet)
            if success {
                dismiss() // Si todo va bien, cerramos la vista
            }
        }
    }
}
