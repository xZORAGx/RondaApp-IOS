// Fichero: RondaApp/Features/Map/Views/MapView.swift
// ✅ VERSIÓN FINAL COMPLETA

import SwiftUI
import MapKit

struct MapView: View {
    
    @StateObject private var viewModel: MapViewModel
    let room: Room
    let roomMembers: [User]
    
    // Estado para el check-in seleccionado que se muestra en la hoja de detalle
    @State private var selectedCheckIn: CheckIn?
    // Estado para mostrar/ocultar la lista de check-ins recientes
    @State private var showRecentCheckIns = false
    
    init(room: Room, members: [User]) {
        _viewModel = StateObject(wrappedValue: MapViewModel(room: room))
        self.room = room
        self.roomMembers = members
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Map(coordinateRegion: $viewModel.region,
                interactionModes: .all,
                showsUserLocation: true,
                annotationItems: viewModel.checkInAnnotations) { checkIn in
                
                MapAnnotation(coordinate: CLLocationCoordinate2D(
                    latitude: checkIn.location?.latitude ?? 0,
                    longitude: checkIn.location?.longitude ?? 0
                )) {
                    CheckInAnnotationView(checkIn: checkIn, user: roomMembers.first { $0.uid == checkIn.userId })
                        .onTapGesture {
                            self.selectedCheckIn = checkIn
                        }
                }
            }
            .ignoresSafeArea(edges: .top)
            .onAppear {
                viewModel.activateListeners()
            }
            .onDisappear {
                viewModel.deactivateListeners()
            }
            // Hoja para mostrar el detalle de un check-in
            .sheet(item: $selectedCheckIn) { checkIn in
                let user = roomMembers.first { $0.uid == checkIn.userId }
                CheckInDetailView(checkIn: checkIn, user: user)
            }
            // Hoja para mostrar la lista de check-ins recientes
            .sheet(isPresented: $showRecentCheckIns) {
                RecentCheckInsListView(
                    checkIns: viewModel.checkInAnnotations,
                    roomMembers: roomMembers,
                    drinks: room.drinks
                ) { selected in
                    // Esta es la acción que se ejecuta al pulsar "Localizar"
                    viewModel.centerOn(checkIn: selected)
                }
            }

            mapControls
                .padding()
        }
    }
    
    private var mapControls: some View {
        VStack(spacing: 12) {
            // Botón para centrar en la ubicación del usuario
            Button(action: viewModel.centerOnUserLocation) {
                Image(systemName: "location.fill")
                    .font(.title2)
                    .padding(12)
                    .background(.black.opacity(0.75))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
            
            // Botón para mostrar la lista de actividad reciente
            Button(action: { showRecentCheckIns = true }) {
                Image(systemName: "list.bullet")
                    .font(.title2)
                    .padding(12)
                    .background(.black.opacity(0.75))
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        }
    }
}

// Vista para la chincheta personalizada en el mapa
struct CheckInAnnotationView: View {
    let checkIn: CheckIn
    let user: User?
    
    var body: some View {
        AsyncImage(url: URL(string: user?.photoURL ?? "")) { image in
            image.resizable().aspectRatio(contentMode: .fill)
        } placeholder: {
            Image(systemName: "person.fill")
                .padding(8)
                .background(.black.opacity(0.5))
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.white, lineWidth: 2))
        .shadow(radius: 5)
        .scaleEffect(1.1)
        .transition(.scale)
    }
}
