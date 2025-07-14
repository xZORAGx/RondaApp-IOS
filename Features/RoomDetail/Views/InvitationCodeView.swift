// Fichero: RondaApp/Features/RoomDetail/Views/InvitationCodeView.swift

import SwiftUI

struct InvitationCodeView: View {
    
    let roomTitle: String
    let invitationCode: String
    
    @State private var justCopied = false
    @Environment(\.dismiss) private var dismiss
    
    // Paleta de colores "Melón"
    private let melonGradient = LinearGradient(
        gradient: Gradient(colors: [Color(red: 1, green: 0.7, blue: 0.6), Color(red: 0.6, green: 0.9, blue: 0.7)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    var body: some View {
        ZStack {
            // Fondo con degradado de colores frescos
            melonGradient.ignoresSafeArea()
            
            VStack(spacing: 25) {
                Spacer()
                
                // Icono más festivo
                Image(systemName: "party.popper.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
                    .shadow(radius: 5)
                
                // Título de la sala
                VStack {
                    Text("Únete a la sala")
                        .font(.headline)
                        .foregroundColor(.white.opacity(0.8))
                    Text(roomTitle)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Tarjeta con el código (efecto de cristal)
                VStack(spacing: 10) {
                    Text("CÓDIGO DE INVITACIÓN")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .foregroundColor(.black.opacity(0.6))
                    
                    Text(invitationCode)
                        .font(.system(size: 40, weight: .heavy, design: .monospaced))
                        .foregroundColor(.black.opacity(0.8))
                        .kerning(5) // Aumenta el espacio entre letras
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial) // Efecto de cristal esmerilado
                .cornerRadius(20)
                
                Spacer()
                
                // Botón de copiar con feedback visual
                Button(action: copyToClipboard) {
                    HStack {
                        Image(systemName: justCopied ? "checkmark.circle.fill" : "doc.on.doc.fill")
                        Text(justCopied ? "¡Copiado!" : "Copiar Código")
                    }
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(justCopied ? .green : .white)
                    .foregroundColor(justCopied ? .white : .black)
                    .cornerRadius(15)
                    .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                }
                
                // Botón para cerrar
                Button("Cerrar") {
                    dismiss()
                }
                .font(.subheadline).fontWeight(.bold)
                .foregroundColor(.white.opacity(0.8))
                .padding(.bottom)
            }
            .padding(30)
        }
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = invitationCode
        withAnimation(.spring()) {
            justCopied = true
        }
        
        // Vuelve al estado original después de 2 segundos
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation(.spring()) {
                justCopied = false
            }
        }
    }
}

#Preview {
    InvitationCodeView(roomTitle: "After del Sábado", invitationCode: "GOAT42")
}
