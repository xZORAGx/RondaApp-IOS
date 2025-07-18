// Fichero: RondaApp/Features/Chat/ViewModels/ChatViewModel.swift

import Foundation
import Combine
import Firebase

@MainActor
class ChatViewModel: ObservableObject {
    
    // --- Propiedades Existentes ---
    @Published var messages: [Message] = []
    @Published var messageText: String = ""
    @Published var memberProfiles: [String: User] = [:]
    
    @Published var isRecording: Bool = false
    @Published var recordingTime: TimeInterval = 0
    
    @Published var playingMessageId: String?
    @Published var playbackProgress: Double = 0.0
    
    // --- ✅ NUEVAS PROPIEDADES PARA DUELOS Y ENCUESTAS ---
    @Published var duels: [Duel] = []
    @Published var polls: [String: Poll] = [:] // [PollID: Poll]
    
    private var recordingTimer: Timer?
    private let room: Room
    let user: User
    private var cancellables = Set<AnyCancellable>()
    
    init(room: Room, user: User) {
        self.room = room
        self.user = user
        // ✅ Renombramos para más claridad, ahora configura TODOS los listeners
        setupListeners()
        fetchMemberProfiles()
    }
    
    // ✅ FUNCIÓN ACTUALIZADA PARA INCLUIR TODOS LOS LISTENERS
    private func setupListeners() {
        guard let roomId = room.id else { return }
        
        // 1. Listener para Mensajes (ya lo tenías)
        ChatService.shared.listenForMessages(roomId: roomId)
            .sink { _ in } receiveValue: { [weak self] messages in
                self?.messages = messages
            }
            .store(in: &cancellables)
            
        // 2. Listener para Duelos (nuevo)
        RoomService.shared.listenToDuels(inRoomId: roomId)
            .sink { _ in } receiveValue: { [weak self] duels in
                self?.duels = duels
            }
            .store(in: &cancellables)
            
        // 3. Listener para Encuestas (nuevo)
        RoomService.shared.listenToPolls(inRoomId: roomId)
            .sink { _ in } receiveValue: { [weak self] polls in
                var pollsDict: [String: Poll] = [:]
                for poll in polls {
                    if let pollId = poll.id {
                        pollsDict[pollId] = poll
                    }
                }
                self?.polls = pollsDict
            }
            .store(in: &cancellables)
    }
    
    private func fetchMemberProfiles() {
        guard !room.memberIds.isEmpty else { return }
        Task {
            let users = try? await UserService.shared.fetchUsers(withIDs: room.memberIds)
            var profiles = [String: User]()
            users?.forEach { user in profiles[user.uid] = user }
            self.memberProfiles = profiles
        }
    }

    func sendTextMessage() {
        guard !messageText.trimmingCharacters(in: .whitespaces).isEmpty, let roomId = room.id else { return }
        let message = Message(authorId: user.uid, timestamp: Timestamp(), mediaType: .text, textContent: messageText)
        self.messageText = ""
        Task { try? await ChatService.shared.sendMessage(message, inRoomId: roomId) }
    }
    
    // ✅ NUEVA FUNCIÓN PARA EMITIR UN VOTO
    func castVote(on poll: Poll, for option: String) async {
        guard let pollId = poll.id,
              let roomId = room.id,
              let duel = duels.first(where: { $0.id == poll.duelId }) else { return }
        
        do {
            try await RoomService.shared.castVote(
                poll: poll,
                duel: duel,
                option: option,
                userId: user.uid,
                inRoomId: roomId
            )
        } catch {
            print("Error al votar: \(error.localizedDescription)")
        }
    }
    
    // --- Lógica de Audio (sin cambios) ---
    
    private func sendMediaMessage(data: Data, type: MediaType, duration: TimeInterval? = nil, samples: [Float]? = nil) async {
        guard let roomId = room.id else { return }
        do {
            let messageId = UUID().uuidString
            let url = try await StorageService.shared.uploadChatMedia(data: data, roomId: roomId, messageId: messageId, mediaType: type)
            let message = Message(authorId: user.uid, timestamp: Timestamp(), mediaType: type, mediaURL: url.absoluteString, duration: duration, waveformSamples: samples)
            try await ChatService.shared.sendMessage(message, inRoomId: roomId)
        } catch { print("Error al enviar media: \(error.localizedDescription)") }
    }
    
    func startAudioRecording() {
        if AudioService.shared.startRecording() {
            isRecording = true
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in self?.recordingTime += 1 }
        }
    }
    
    func stopAndSendAudioRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        recordingTime = 0
        isRecording = false
        
        guard let audioData = AudioService.shared.stopRecording(),
              let samples = AudioService.shared.generateWaveformSamples(from: audioData.url) else { return }
        
        Task {
            do {
                let data = try Data(contentsOf: audioData.url)
                await sendMediaMessage(data: data, type: .audio, duration: audioData.duration, samples: samples)
            } catch { print("Error al leer el fichero de audio: \(error)") }
        }
    }
    
    func togglePlayback(for message: Message) {
        guard let messageId = message.id, message.mediaType == .audio else { return }
        
        if playingMessageId == messageId {
            AudioService.shared.stopPlayback()
        } else {
            AudioService.shared.stopPlayback()
            self.playbackProgress = 0.0
            
            guard let urlString = message.mediaURL, let url = URL(string: urlString) else { return }
            
            URLSession.shared.dataTask(with: url) { data, _, error in
                guard let data = data, error == nil else {
                    DispatchQueue.main.async { self.playingMessageId = nil }
                    return
                }
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(messageId).m4a")
                do {
                    try data.write(to: tempURL, options: .atomic)
                    DispatchQueue.main.async {
                        self.playingMessageId = messageId
                        AudioService.shared.playAudio(
                            from: tempURL,
                            onProgress: { progress in
                                self.playbackProgress = progress
                            },
                            onFinish: {
                                self.playingMessageId = nil
                                self.playbackProgress = 0.0
                            }
                        )
                    }
                } catch { DispatchQueue.main.async { self.playingMessageId = nil } }
            }.resume()
        }
    }
}
