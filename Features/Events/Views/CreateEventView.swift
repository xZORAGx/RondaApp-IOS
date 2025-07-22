
//
//  CreateEventView.swift
//  RondaApp
//
//  Created by David on 21/7/25.
//

import SwiftUI

struct CreateEventView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject var viewModel: CreateEventViewModel

    init(roomId: String) {
        _viewModel = StateObject(wrappedValue: CreateEventViewModel(roomId: roomId))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detalles del Evento")) {
                    TextField("Título del Evento", text: $viewModel.title)
                    TextField("Descripción (Opcional)", text: $viewModel.description)

                    DatePicker("Fecha de Inicio", selection: $viewModel.startDate, displayedComponents: .date)
                    DatePicker("Fecha de Fin", selection: $viewModel.endDate, displayedComponents: .date)

                    // Color Picker (Conceptual)
                    ColorPicker("Color del Evento", selection: Binding(get: {
                        Color(hex: viewModel.customColor) ?? .accentColor
                    }, set: { newColor in
                        // Convert Color to Hex String
                        let uiColor = UIColor(newColor)
                        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                        viewModel.customColor = String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
                    }))
                }

                Section(header: Text("Participantes")) {
                    if viewModel.isLoadingUsers {
                        ProgressView("Cargando usuarios...")
                    } else if viewModel.availableUsers.isEmpty {
                        Text("No hay usuarios disponibles.")
                    } else {
                        List {
                            ForEach(viewModel.availableUsers) { user in
                                Button {
                                    if viewModel.selectedParticipants.contains(where: { $0.uid == user.uid }) {
                                        viewModel.selectedParticipants.removeAll(where: { $0.uid == user.uid })
                                    } else {
                                        viewModel.selectedParticipants.append(user)
                                    }
                                } label: {
                                    HStack {
                                        UserAvatarView(user: user, size: 30)
                                        Text(user.username ?? "Usuario Desconocido")
                                            .foregroundColor(.primary)
                                        Spacer()
                                        if viewModel.selectedParticipants.contains(where: { $0.uid == user.uid }) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                            }
                        }
                        .frame(height: min(CGFloat(viewModel.availableUsers.count) * 50, 200)) // Adjust height dynamically
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button("Crear Evento") {
                    Task {
                        await viewModel.createEvent()
                        if viewModel.eventCreatedSuccessfully {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.isLoading || viewModel.title.isEmpty)
            }
            .navigationTitle("Nuevo Evento")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct CreateEventView_Previews: PreviewProvider {
    static var previews: some View {
        CreateEventView(roomId: "previewRoomId")
    }
}
