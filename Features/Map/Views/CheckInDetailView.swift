//
//  CheckInDetailView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 18/7/25.
//

// Fichero: RondaApp/Features/Map/Views/CheckInDetailView.swift

import SwiftUI
import MapKit

struct CheckInDetailView: View {
    
    let checkIn: CheckIn
    let user: User?
    @Environment(\.dismiss) private var dismiss
    
    // Estado para guardar la dirección una vez la obtengamos.
    @State private var address: String = "Cargando dirección..."
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            ScrollView {
                VStack(spacing: 0) {
                    // La foto principal del momento
                    AsyncImage(url: URL(string: checkIn.photoURL ?? "")) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle().fill(.gray.opacity(0.3)).aspectRatio(16/9, contentMode: .fit)
                    }
                    .frame(height: 300)
                    .clipped()

                    // Contenido con la información
                    VStack(alignment: .leading, spacing: 16) {
                        userInfo
                        Divider()
                        timestampInfo
                        if let caption = checkIn.caption, !caption.isEmpty {
                            captionInfo(caption: caption)
                            Divider()
                        }
                        addressInfo
                        openInMapsButton
                    }
                    .padding()
                }
            }
            .background(Color(.systemGroupedBackground))
            .ignoresSafeArea()

            // Botón de cerrar
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.body.bold())
                    .foregroundColor(.primary)
                    .padding(10)
                    .background(.thinMaterial)
                    .clipShape(Circle())
            }
            .padding()
        }
        .onAppear(perform: getAddressFromCoordinates)
    }
    
    // MARK: - Subvistas
    
    private var userInfo: some View {
        HStack {
            AsyncImage(url: URL(string: user?.photoURL ?? "")) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.fill").foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .background(.gray.opacity(0.2))
            .clipShape(Circle())
            
            Text(user?.username ?? "Alguien")
                .font(.title2)
                .fontWeight(.bold)
        }
    }
    
    private var timestampInfo: some View {
        HStack {
            Image(systemName: "clock.fill")
                .foregroundColor(.secondary)
                .frame(width: 25)
            Text(checkIn.timestamp.dateValue(), style: .relative) + Text(" atrás")
        }
    }
    
    private func captionInfo(caption: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "text.bubble.fill")
                .foregroundColor(.secondary)
                .frame(width: 25)
            Text(caption)
        }
    }
    
    private var addressInfo: some View {
        HStack(alignment: .top) {
            Image(systemName: "mappin.circle.fill")
                .foregroundColor(.secondary)
                .frame(width: 25)
            Text(address)
        }
    }
    
    private var openInMapsButton: some View {
        Button(action: openInAppleMaps) {
            Label("Ver en Apple Maps", systemImage: "arrow.triangle.turn.up.right.diamond.fill")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(.accentColor)
    }
    
    // MARK: - Lógica
    
    /// Convierte las coordenadas del CheckIn a una dirección legible.
    private func getAddressFromCoordinates() {
        guard let location = checkIn.location else {
            address = "No se proporcionó ubicación"; return
        }
        let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let geocoder = CLGeocoder()
        
        geocoder.reverseGeocodeLocation(clLocation) { placemarks, error in
            if let placemark = placemarks?.first {
                address = [placemark.thoroughfare, placemark.subThoroughfare, placemark.locality]
                    .compactMap { $0 }
                    .joined(separator: ", ")
            } else {
                address = "Dirección no encontrada"
            }
        }
    }
    
    /// Abre la aplicación de Mapas de Apple con un pin en la ubicación.
    private func openInAppleMaps() {
        guard let location = checkIn.location else { return }
        let coordinate = CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = "\(user?.username ?? "Usuario") estuvo aquí"
        mapItem.openInMaps()
    }
}
