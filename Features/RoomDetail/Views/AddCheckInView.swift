//
//  AddCheckInView.swift
//  RondaApp
//
//  Created by David Roger Alvarez on 18/7/25.
//

// Fichero: RondaApp/Features/RoomDetail/Views/AddCheckInView.swift

import SwiftUI
import PhotosUI
import CoreLocation
import FirebaseFirestore // Necesario para el tipo GeoPoint

struct AddCheckInView: View {
    
    // MARK: - Properties
    
    @ObservedObject var viewModel: RoomDetailViewModel
    @StateObject private var locationManager = LocationManager()
    @Environment(\.dismiss) private var dismiss
    
    // Estados internos para los campos del formulario
    @State private var selectedDrinkId: String
    @State private var caption: String = ""
    @State private var shareLocation: Bool = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var isSaving: Bool = false
    
    private var isFormValid: Bool {
        !selectedDrinkId.isEmpty && !isSaving
    }
    
    // Inicializador que coge el ViewModel y selecciona la primera bebida por defecto.
    init(viewModel: RoomDetailViewModel) {
        self.viewModel = viewModel
        _selectedDrinkId = State(initialValue: viewModel.room.drinks.first?.id ?? "")
    }

    // MARK: - Body
    
    var body: some View {
        NavigationView {
            Form {
                // Sección 1: La bebida (el núcleo de la acción)
                Section("¿Qué estás bebiendo?") {
                    Picker("Bebida", selection: $selectedDrinkId) {
                        ForEach(viewModel.room.drinks) { drink in
                            Text("\(drink.emoji ?? "") \(drink.name)").tag(drink.id)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Sección 2: El "Momento" (Foto y Título)
                Section("Comparte el momento (opcional)") {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        imagePlaceholder
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            selectedImageData = try? await newItem?.loadTransferable(type: Data.self)
                        }
                    }
                    
                    if selectedImageData != nil {
                        TextField("Añade un título a tu foto...", text: $caption, axis: .vertical)
                            .lineLimit(3)
                    }
                }
                
                // Sección 3: La Ubicación
                Section("Ubicación (opcional)") {
                    Toggle(isOn: $shareLocation) {
                        Label("Publicar dónde estoy", systemImage: "mappin.and.ellipse")
                    }
                    .tint(.purple)
                    .onChange(of: shareLocation) { _, newValue in
                        if newValue {
                            locationManager.requestLocationPermission()
                        }
                    }
                    
                    // Mostramos un aviso si el usuario ha denegado los permisos
                    if locationManager.authorizationStatus == .denied {
                        Text("Has denegado el permiso de ubicación. Actívalo en Ajustes para usar esta función.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Sección 4: Botón de Acción
                Section {
                    Button(action: processAndCreateCheckIn) {
                        if isSaving {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            Text("Añadir Ronda")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    }
                    .disabled(!isFormValid)
                }
            }
            .navigationTitle("Nuevo Momento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
    }
    
    // MARK: - Subvistas
    
    @ViewBuilder
    private var imagePlaceholder: some View {
        HStack(spacing: 16) {
            // Placeholder visual para la foto
            ZStack {
                Color.secondary.opacity(0.1)
                if let data = selectedImageData, let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "photo.fill.on.rectangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.secondary.opacity(0.5))
                }
            }
            .frame(width: 80, height: 80)
            .cornerRadius(12)
            
            Text(selectedImageData == nil ? "Añadir una foto" : "Cambiar foto")
                .foregroundColor(.accentColor)
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Lógica de Creación
    
    private func processAndCreateCheckIn() {
        guard let userId = viewModel.currentUser?.uid,
              let roomId = viewModel.room.id else {
            viewModel.errorMessage = "Error de usuario o de sala."
            dismiss()
            return
        }
        
        isSaving = true
        
        Task {
            var location: GeoPoint? = nil
            if shareLocation, let clLocation = await getLocation() {
                location = GeoPoint(latitude: clLocation.coordinate.latitude, longitude: clLocation.coordinate.longitude)
            }
            
            var photoURL: String? = nil
            if let imageData = selectedImageData {
                let tempCheckInId = UUID().uuidString
                photoURL = try? await StorageService.shared.uploadCheckInImage(
                    data: imageData, roomId: roomId, checkInId: tempCheckInId
                ).absoluteString
            }
            
            let newCheckIn = CheckIn(
                userId: userId, roomId: roomId, drinkId: selectedDrinkId,
                photoURL: photoURL,
                caption: caption.isEmpty ? nil : caption,
                location: location
            )
            
            let success = await viewModel.createCheckIn(newCheckIn)
            
            if success {
                dismiss()
            } else {
                isSaving = false
            }
        }
    }
    
    private func getLocation() async -> CLLocation? {
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
            // Esperamos un máximo de 3 segundos para obtener la ubicación
            for _ in 0..<30 {
                if let location = locationManager.userLocation { return location }
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        return locationManager.userLocation
    }
}
