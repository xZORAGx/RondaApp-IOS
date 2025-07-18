//
//  RecentCheckInsListView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 18/7/25.
//

// Fichero: RondaApp/Features/Map/Views/RecentCheckInsListView.swift

import SwiftUI

struct RecentCheckInsListView: View {
    
    // Los datos que necesita esta vista
    let checkIns: [CheckIn]
    let roomMembers: [User]
    let drinks: [Drink]
    
    // La acción que se ejecutará cuando el usuario pulse "Localizar"
    let onSelectCheckIn: (CheckIn) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    // Filtramos y ordenamos los check-ins para mostrar solo los de las últimas 24h
    private var recentCheckIns: [CheckIn] {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        return checkIns
            .filter { $0.timestamp.dateValue() > twentyFourHoursAgo }
            .sorted { $0.timestamp.dateValue() > $1.timestamp.dateValue() }
    }
    
    var body: some View {
        NavigationView {
            List(recentCheckIns) { checkIn in
                let user = roomMembers.first { $0.uid == checkIn.userId }
                let drink = drinks.first { $0.id == checkIn.drinkId }
                
                CheckInRowView(checkIn: checkIn, user: user, drink: drink) {
                    // Al pulsar el botón de la fila, ejecutamos la acción
                    onSelectCheckIn(checkIn)
                    // Y cerramos la hoja
                    dismiss()
                }
            }
            .listStyle(.plain)
            .navigationTitle("Actividad (Últimas 24h)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
}

// Vista auxiliar para cada fila de la lista
struct CheckInRowView: View {
    let checkIn: CheckIn
    let user: User?
    let drink: Drink?
    let onLocate: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: user?.photoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.fill").foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .background(Color.secondary.opacity(0.1))
            .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(user?.username ?? "Alguien")
                    .fontWeight(.bold)
                Text("Tomó \(drink?.name ?? "una bebida")")
                    .font(.subheadline)
                Text(checkIn.timestamp.dateValue(), style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    + Text(" atrás")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onLocate) {
                Label("Localizar", systemImage: "mappin.and.ellipse")
            }
            .buttonStyle(.bordered)
        }
        .padding(.vertical, 8)
    }
}
