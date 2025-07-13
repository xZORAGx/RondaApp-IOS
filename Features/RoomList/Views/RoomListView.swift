//  RondaApp/Features/RoomList/Views/RoomListView.swift

import SwiftUI

struct RoomListView: View {
    
    let user: User
    @ObservedObject var sessionManager: SessionManager
    
    @StateObject private var viewModel: RoomListViewModel
    
    @State private var isShowingCreateSheet = false
    
    init(user: User, sessionManager: SessionManager) {
        self.user = user
        self.sessionManager = sessionManager
        self._viewModel = StateObject(wrappedValue: RoomListViewModel(user: user))
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                VStack(spacing: 0) {
                    if viewModel.rooms.isEmpty && !viewModel.isLoading {
                        emptyStateView
                    } else {
                        List {
                            ForEach(viewModel.rooms) { room in
                                NavigationLink(destination: Text("Vista de detalle para \(room.title)")) {
                                    RoomRowView(room: room)
                                }
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .background(Color(.systemGroupedBackground))
                        .refreshable {
                            viewModel.loadRooms()
                        }
                    }
                    
                    actionButtons
                }
                
                if viewModel.isLoading {
                    ProgressView()
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
                Text(viewModel.errorMessage ?? "")
            })
            .sheet(isPresented: $isShowingCreateSheet) {
                CreateRoomView(viewModel: viewModel)
            }
        }
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
            Button(action: { /* Lógica para unirse a sala */ }) {
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
        .padding(.horizontal)
        .padding(.bottom)
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.bottom))
    }
}

// MARK: - Vista para cada fila de la lista (Tarjeta de Sala)

struct RoomRowView: View {
    let room: Room
    
    var body: some View {
        HStack(spacing: 16) {
            // ✅ INICIO DE LA MODIFICACIÓN
            AsyncImage(url: URL(string: room.photoURL ?? "")) { phase in
                switch phase {
                case .empty:
                    // Mientras carga
                    ProgressView()
                case .success(let image):
                    // Si la imagen se carga con éxito
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    // Si falla la carga o la URL es nula, muestra el icono por defecto
                    Image(systemName: "person.3.sequence.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 50, height: 50)
            .background(Color.blue.opacity(0.1))
            .clipShape(Circle())
            // ✅ FIN DE LA MODIFICACIÓN

            VStack(alignment: .leading, spacing: 4) {
                Text(room.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Label("\(room.memberIds.count) miembros", systemImage: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Preview

#Preview {
    let previewUser = User(uid: "123", email: "preview@user.com", username: "PreviewUser", age: 25, hasAcceptedPolicy: true, hasCompletedProfile: true)
    let sessionManager = SessionManager()
    
    return RoomListView(user: previewUser, sessionManager: sessionManager)
}
