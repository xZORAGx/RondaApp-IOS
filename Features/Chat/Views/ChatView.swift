// Fichero: RondaApp/Features/Chat/Views/ChatView.swift

import SwiftUI

struct ChatView: View {
    
    @StateObject var viewModel: ChatViewModel
    @Namespace var bottomId
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        messageListView
            .background(ChatBackgroundView())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                chatInputBar
            }
            .navigationTitle("Chat de la Sala")
            .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Sub-vistas
    
    private var messageListView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(viewModel.messages) { message in
                        MessageBubbleView(
                            message: message,
                            isFromCurrentUser: message.authorId == viewModel.user.uid,
                            authorName: viewModel.memberProfiles[message.authorId]?.username,
                            isPlaying: viewModel.playingMessageId == message.id,
                            playbackProgress: viewModel.playbackProgress,
                            viewModel: viewModel,
                            onPlayButtonTapped: {
                                viewModel.togglePlayback(for: message)
                            }
                        )
                    }
                    Color.clear.frame(height: 1).id(bottomId)
                }
                .padding(.top, 10)
            }
            .onTapGesture {
                isTextFieldFocused = false
            }
            .onAppear { proxy.scrollTo(bottomId, anchor: .bottom) }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation { proxy.scrollTo(bottomId, anchor: .bottom) }
            }
        }
    }
    
    private var chatInputBar: some View {
        HStack(spacing: 12) {
            if viewModel.isRecording {
                Image(systemName: "mic.fill").foregroundColor(.red)
                Text(formatTime(viewModel.recordingTime)).font(.body.monospacedDigit()).fontWeight(.semibold)
                Spacer()
                Button(action: viewModel.stopAndSendAudioRecording) {
                    Text("Enviar").fontWeight(.bold)
                }
                .foregroundColor(.blue)
            } else {
                TextField("Escribe algo...", text: $viewModel.messageText)
                    .focused($isTextFieldFocused)
                
                if viewModel.messageText.isEmpty {
                    Button(action: viewModel.startAudioRecording) {
                        Image(systemName: "mic.fill").font(.system(size: 20))
                    }
                    .foregroundColor(.accentColor)
                } else {
                    Button(action: viewModel.sendTextMessage) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.blue)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .padding(.horizontal)
        .padding(.top, 5)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
                .frame(height: 50)
            , alignment: .bottom
        )
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02i:%02i", minutes, seconds)
    }
}


// --- VISTAS COMPLEMENTARIAS ---

struct ChatBackgroundView: View {
    @State private var animate = false
    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.0, blue: 0.1).ignoresSafeArea()
            Circle().fill(Color.purple.opacity(0.4)).frame(width: 300).offset(x: -100, y: -200).blur(radius: 100).rotationEffect(.degrees(animate ? 360 : 0))
            Circle().fill(Color.blue.opacity(0.4)).frame(width: 250).offset(x: 100, y: 150).blur(radius: 120).rotationEffect(.degrees(animate ? -360 : 0))
        }.onAppear { withAnimation(.linear(duration: 40).repeatForever(autoreverses: false)) { animate = true } }
    }
}

struct WaveformView: View {
    let samples: [Float]
    let progress: Double
    let color: Color
    let progressColor: Color
    
    var body: some View {
        ZStack(alignment: .leading) {
            HStack(spacing: 2) {
                ForEach(0..<samples.count, id: \.self) { index in
                    Capsule().frame(width: 3, height: CGFloat(samples[index]) * 50).foregroundColor(color)
                }
            }
            HStack(spacing: 2) {
                ForEach(0..<samples.count, id: \.self) { index in
                    Capsule().frame(width: 3, height: CGFloat(samples[index]) * 50).foregroundColor(progressColor)
                }
            }
            .mask(alignment: .leading) {
                Rectangle().frame(width: max(0, CGFloat(progress) * 180))
            }
        }
    }
}

struct MessageBubbleView: View {
    let message: Message
    let isFromCurrentUser: Bool
    let authorName: String?
    let isPlaying: Bool
    let playbackProgress: Double
    @ObservedObject var viewModel: ChatViewModel
    let onPlayButtonTapped: () -> Void
    
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter(); formatter.dateStyle = .none; formatter.timeStyle = .short; return formatter
    }()
    
    var body: some View {
        HStack {
            if isFromCurrentUser { Spacer(minLength: 50) }
            VStack(alignment: isFromCurrentUser ? .trailing : .leading, spacing: 5) {
                if !isFromCurrentUser && message.authorId != "system" {
                    Text(authorName ?? "Usuario").font(.caption).fontWeight(.bold).foregroundColor(.accentColor)
                } else if message.authorId == "system" {
                    Text("RondaApp Bot").font(.caption).fontWeight(.bold).foregroundColor(.purple)
                }
                content
                Text(Self.timeFormatter.string(from: message.timestamp.dateValue())).font(.caption2).foregroundColor(isFromCurrentUser ? .white.opacity(0.8) : .secondary)
            }
            .padding(.vertical, 10).padding(.horizontal, 14).background(bubbleBackground).foregroundColor(bubbleForeground).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            if !isFromCurrentUser { Spacer(minLength: 50) }
        }.padding(.horizontal)
    }
    
    @ViewBuilder
    private var content: some View {
        switch message.mediaType {
        case .text: Text(message.textContent ?? "")
        case .audio:
            HStack(spacing: 10) {
                Button(action: onPlayButtonTapped) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill").font(.body.weight(.semibold)).frame(width: 20)
                }
                if let samples = message.waveformSamples {
                    WaveformView(samples: samples, progress: isPlaying ? playbackProgress : 0, color: isFromCurrentUser ? .white.opacity(0.5) : .gray.opacity(0.6), progressColor: isFromCurrentUser ? .white : .blue)
                } else { Rectangle().frame(height: 2) }
                Text(formatTime(message.duration ?? 0)).font(.caption.monospacedDigit())
            }.frame(minWidth: 180)
        case .poll:
            if let pollId = message.pollId, let poll = viewModel.polls[pollId], let duel = viewModel.duels.first(where: { $0.id == poll.duelId }) {
                PollMessageView(poll: poll, duel: duel, viewModel: viewModel)
            } else if let duelId = message.duelId, let duel = viewModel.duels.first(where: { $0.id == duelId }), duel.status == .resolved {
                // ✅ Usamos la nueva función auxiliar para mantener la vista limpia
                VStack(alignment: .leading, spacing: 8) {
                    Text("Encuesta finalizada.").font(.subheadline).fontWeight(.bold)
                    // Usamos try! para convertir el texto formateado en un Text.
                    // Es seguro aquí porque sabemos que el formato es correcto.
                    Text(try! AttributedString(markdown: "Ganador: **\(getWinnerName(for: duel))**"))
                        .font(.body)
                }
            } else {
                Text("Encuesta finalizada.").font(.subheadline).italic()
            }
        }
    }
    
    // ✅ FUNCIÓN AUXILIAR PARA OBTENER EL NOMBRE DEL GANADOR
    private func getWinnerName(for duel: Duel) -> String {
        if let winnerId = duel.winnerId {
            if winnerId == "draw" {
                return "Empate"
            } else {
                return viewModel.memberProfiles[winnerId]?.username ?? "Desconocido"
            }
        }
        return "No decidido"
    }
    
    private var bubbleBackground: Color {
        if isFromCurrentUser { return .blue }
        if message.authorId == "system" { return .purple.opacity(0.8) }
        return Color(.systemGray5)
    }
    
    private var bubbleForeground: Color {
        if isFromCurrentUser || message.authorId == "system" { return .white }
        return .primary
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60; let seconds = Int(time) % 60; return String(format: "%02i:%02i", minutes, seconds)
    }
}
