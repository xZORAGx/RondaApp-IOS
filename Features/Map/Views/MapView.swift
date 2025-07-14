//
//  MapView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 14/7/25.
//

// Fichero: RondaApp/Features/RoomDetail/Views/Tabs/MapView.swift

import SwiftUI
import MapKit // Importamos MapKit para el mapa

struct MapView: View {
    // Coordenadas de ejemplo (puedes centrarlas donde quieras)
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891), // Centro de Zaragoza
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )

    var body: some View {
        // El mapa ocupará toda la pantalla
        Map(coordinateRegion: $region)
            .ignoresSafeArea(edges: .top) // Hacemos que el mapa llegue hasta arriba
            .overlay(
                // Un texto flotante para dar contexto
                Text("Aquí verás la ubicación de tus amigos")
                    .padding()
                    .background(.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(),
                alignment: .top
            )
    }
}

#Preview {
    MapView()
}
