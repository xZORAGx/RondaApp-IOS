// Fichero: RondaApp/Features/Map/ViewModels/MapViewModel.swift
// ✅ VERSIÓN FINAL Y ROBUSTA

import Foundation
import MapKit
import Combine

@MainActor
class MapViewModel: ObservableObject {
    
    @Published var checkInAnnotations: [CheckIn] = []
    @Published var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.6488, longitude: -0.8891), // Zaragoza
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    )
    
    private let room: Room
    private let locationManager = LocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    init(room: Room) {
        self.room = room
    }
    
    // ✅ NUEVO: Para limpiar y ahorrar batería cuando la vista desaparece
    func deactivateListeners() {
            locationManager.stopUpdatingLocation()
        }
    
    func activateListeners() {
        setupLocationListener()
        setupCheckInsListener()
        // Empezamos a buscar la ubicación en cuanto la vista aparece
        locationManager.startUpdatingLocation()
    }
    
    func centerOnUserLocation() {
        guard let userLocation = locationManager.userLocation else {
            // Si no hay ubicación aún, pedimos una nueva
            locationManager.startUpdatingLocation()
            return
        }
        region = MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    }
    
    func frameAllAnnotations() {
        let twentyFourHoursAgo = Date().addingTimeInterval(-24 * 60 * 60)
        let recentAnnotations = checkInAnnotations.filter {
            $0.timestamp.dateValue() > twentyFourHoursAgo
        }
        guard !recentAnnotations.isEmpty else { return }
        
        var zoomRect = MKMapRect.null
        for annotation in recentAnnotations {
            if let location = annotation.location {
                let point = MKMapPoint(CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude))
                zoomRect = zoomRect.union(MKMapRect(x: point.x, y: point.y, width: 0.1, height: 0.1))
            }
        }
        region = MKCoordinateRegion(zoomRect)
    }
    
    private func setupLocationListener() {
        locationManager.requestLocationPermission()
        
        // Este 'sink' ahora se usa para centrar el mapa LA PRIMERA VEZ que obtenemos la ubicación.
        locationManager.$userLocation
            .compactMap { $0 }
            .first() // Solo reacciona a la primera ubicación válida
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                self?.region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
                )
            }
            .store(in: &cancellables)
    }
    
    private func setupCheckInsListener() {
        guard let roomId = room.id else { return }
        RoomService.shared.listenToCheckIns(inRoomId: roomId)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] checkIns in
                self?.checkInAnnotations = checkIns
            })
            .store(in: &cancellables)
    }
    
    func centerOn(checkIn: CheckIn) {
            guard let location = checkIn.location else { return }
            
            region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude),
                // Hacemos un zoom más cercano para ver el detalle
                span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
            )
        }
    
}
