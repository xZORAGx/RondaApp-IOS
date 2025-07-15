// Fichero: RondaApp/Core/Services/AudioService.swift

import Foundation
import AVFoundation

class AudioService: NSObject, AVAudioPlayerDelegate {
    
    static let shared = AudioService()
    
    // MARK: - Private Properties
    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    
    private var audioFileURL: URL?
    
    // Propiedades para el progreso y la finalización
    private var progressTimer: Timer?
    private var onPlaybackProgressUpdate: ((Double) -> Void)?
    private var onPlaybackDidFinish: (() -> Void)?
    
    override private init() {
        super.init()
    }
    
    // MARK: - Recording
    
    func startRecording() -> Bool {
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            audioFileURL = documentsPath.appendingPathComponent("RondaApp_recording.m4a")
            
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 12000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            guard let url = audioFileURL else { return false }
            
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.record()
            
            return true
            
        } catch {
            print("Error al iniciar la grabación: \(error.localizedDescription)")
            return false
        }
    }
    
    func stopRecording() -> (url: URL, duration: TimeInterval)? {
        guard let recorder = audioRecorder, let url = audioFileURL else { return nil }
        recorder.stop()
        let audioAsset = AVURLAsset(url: url)
        let duration = CMTimeGetSeconds(audioAsset.duration)
        do {
            try audioSession.setActive(false)
        } catch {
            print("Error al detener la sesión de audio: \(error.localizedDescription)")
        }
        self.audioRecorder = nil
        self.audioFileURL = nil
        return (url, duration)
    }

    // MARK: - Waveform Generation
    
    func generateWaveformSamples(from url: URL, count: Int = 40) -> [Float]? {
        do {
            let file = try AVAudioFile(forReading: url)
            guard let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: file.fileFormat.sampleRate, channels: file.fileFormat.channelCount, interleaved: false),
                  let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(file.length)) else { return nil }
            
            try file.read(into: buffer)
            guard let floatData = buffer.floatChannelData?[0] else { return nil }
            
            let frameLength = Int(buffer.frameLength)
            let chunkSize = frameLength / count
            var samples: [Float] = []
            
            for i in 0..<count {
                let chunk = floatData.advanced(by: i * chunkSize)
                var max: Float = 0
                for j in 0..<chunkSize {
                    max = Swift.max(max, abs(chunk[j]))
                }
                samples.append(max)
            }
            
            let maxSample = samples.max() ?? 1.0
            return samples.map { $0 / maxSample }
            
        } catch {
            print("Error al procesar el fichero de audio: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Playback
    
    func playAudio(from localURL: URL, onProgress: @escaping (Double) -> Void, onFinish: @escaping () -> Void) {
        if audioPlayer?.isPlaying == true { stopPlayback() }
        
        self.onPlaybackProgressUpdate = onProgress
        self.onPlaybackDidFinish = onFinish
        
        do {
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            
            audioPlayer = try AVAudioPlayer(contentsOf: localURL)
            audioPlayer?.delegate = self
            
            if audioPlayer?.play() == true {
                progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                    self?.updatePlaybackProgress()
                }
            } else {
                onPlaybackDidFinish?()
            }
        } catch {
            print("Error al reproducir el audio: \(error.localizedDescription)")
            onPlaybackDidFinish?()
        }
    }
    
    func stopPlayback() {
        audioPlayer?.stop()
        progressTimer?.invalidate()
        progressTimer = nil
        onPlaybackDidFinish?()
        onPlaybackDidFinish = nil
        onPlaybackProgressUpdate = nil
    }
    
    private func updatePlaybackProgress() {
        guard let player = audioPlayer, player.duration > 0 else { return }
        let progress = player.currentTime / player.duration
        onPlaybackProgressUpdate?(progress)
    }
    
    // MARK: - AVAudioPlayerDelegate
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        progressTimer?.invalidate()
        progressTimer = nil
        onPlaybackDidFinish?()
        onPlaybackDidFinish = nil
        onPlaybackProgressUpdate = nil
        do {
            try audioSession.setActive(false)
        } catch {
            print("Error al desactivar la sesión de audio: \(error.localizedDescription)")
        }
    }
}
