import Foundation
import AVFoundation
import AppKit

public final class AudioVoiceoverEngine: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = AudioVoiceoverEngine()
    
    private let synthesizer = AVSpeechSynthesizer()
    private weak var player: AVPlayer?
    private var baseVolume: Float = 1.0
    private var lastSpokenText: String = ""
    
    @Published public var isVoiceoverEnabled: Bool = false
    @Published public var duckingFactor: Float = 0.20
    
    public override init() {
        super.init()
        synthesizer.delegate = self
    }
    
    public func attach(player: AVPlayer) {
        self.player = player
    }
    
    public func setBaseVolume(_ volume: Float) {
        self.baseVolume = volume
    }
    
    public func speakCue(text: String, languageCode: String) {
        guard isVoiceoverEnabled else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean != lastSpokenText else { return }
        
        lastSpokenText = clean
        
        // Stop any current utterance
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: clean)
        
        // Map language code to BCP-47 identifier
        let bcp47 = Self.bcp47Code(for: languageCode)
        if let voice = AVSpeechSynthesisVoice(language: bcp47) {
            utterance.voice = voice
        }
        
        // Natural speech rate
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate
        
        // Duck original video audio
        if let p = player {
            p.volume = baseVolume * duckingFactor
        }
        
        synthesizer.speak(utterance)
    }
    
    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        restoreVolume()
        lastSpokenText = ""
    }
    
    private func restoreVolume() {
        if let p = player {
            p.volume = baseVolume
        }
    }
    
    // MARK: - AVSpeechSynthesizerDelegate
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        restoreVolume()
    }
    
    public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        restoreVolume()
    }
    
    public static func bcp47Code(for lang: String) -> String {
        switch lang.lowercased() {
        case "it": return "it-IT"
        case "es": return "es-ES"
        case "fr": return "fr-FR"
        case "de": return "de-DE"
        case "pt": return "pt-BR"
        case "ja": return "ja-JP"
        case "zh": return "zh-CN"
        default: return "en-US"
        }
    }
}
