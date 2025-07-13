// Fichero: RondaApp/Features/RoomList/Views/RoomListView.swift

import SwiftUI

struct RoomListView: View {
    
    // MARK: - Properties
    
    @ObservedObject var sessionManager: SessionManager
    @StateObject private var viewModel: RoomListViewModel
    
    @State private var isShowingCreateSheet = false
    @State private var roomToLeave: Room?
    
    private let user: User
    
    // MARK: - Initializer
    
    init(user: User, sessionManager: SessionManager) {
        self.user = user
        self.sessionManager = sessionManager
        _viewModel = StateObject(wrappedValue: RoomListViewModel(user: user))
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.rooms.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        roomList
                    }
                    actionButtons
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
            .navigationTitle("Mis Salas")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Salir") { sessionManager.signOut() }.tint(.red)
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil), actions: {
                Button("OK", role: .cancel) { viewModel.errorMessage = nil }
            }, message: {
                Text(viewModel.errorMessage ?? "Ha ocurrido un error desconocido.")
            })
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateRoomView(viewModel: viewModel)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var roomList: some View {
        List {
            ForEach(viewModel.rooms) { room in
                NavigationLink(destination: RoomDetailView(room: room, user: user)){
                    RoomRowView(room: room)
                }
            }
            .onDelete(perform: markRoomForLeaving)
            
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .refreshable {
            viewModel.loadRooms()
        }
        .alert("¿Salir de la sala?", isPresented: .constant(roomToLeave != nil), actions: {
            Button("Cancelar", role: .cancel) { roomToLeave = nil }
            Button("Salir", role: .destructive) {
                if let room = roomToLeave {
                    viewModel.leaveRoom(room)
                }
                roomToLeave = nil
            }
        }, message: {
            Text("Si sales, necesitarás una nueva invitación para volver a entrar en \"\(roomToLeave?.title ?? "esta sala")\".")
        })
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "house.and.flag.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            Text("Aún no tienes salas")
                .font(.title2)
                .fontWeight(.bold)
            Text("Crea una nueva sala para empezar a registrar tus rondas con amigos.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { /* TODO: Lógica para unirse a sala */ }) {
                Label("Unirse a una Sala", systemImage: "person.badge.plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            
            Button(action: { isShowingCreateSheet = true }) {
                Label("Crear Nueva Sala", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
    /// Guarda la sala que el usuario quiere abandonar para mostrar el diálogo de confirmación.
    private func markRoomForLeaving(at offsets: IndexSet) {
        if let index = offsets.first {
            roomToLeave = viewModel.rooms[index]
        }
    }
}

// MARK: - Vista para cada fila de la lista (Tarjeta de Sala)

struct RoomRowView: View {
    let room: Room
    
    /// Propiedad computada que devuelve una URL válida solo si la cadena no es nula ni vacía.
    private var imageURL: URL? {
        if let urlString = room.photoURL, !urlString.isEmpty {
            return URL(string: urlString)
        }
        return nil
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Lógica de imagen segura:
            if let url = imageURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty: ProgressView()
                    case .success(let image): image.resizable().aspectRatio(contentMode: .fill)
                    case .failure: placeholderImage
                    @unknown default: EmptyView()
                    }
                }
            } else {
                // Si no hay URL, muestra el placeholder directamente.
                placeholderImage
            }
        }
        .frame(width: 50, height: 50)
        .background(Color.secondary.opacity(0.1))
        .clipShape(Circle())
        
        VStack(alignment: .leading, spacing: 4) {
            Text(room.title).font(.headline).fontWeight(.semibold)
            Label("\(room.memberIds.count) miembros", systemImage: "person.2.fill")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        
        Spacer()
    }
    
    /// Vista de placeholder reutilizable para la imagen de la sala.
    private var placeholderImage: some View {
        Image(systemName: "person.3.sequence.fill")
            .font(.title2)
            .foregroundColor(.secondary)
    }
}
