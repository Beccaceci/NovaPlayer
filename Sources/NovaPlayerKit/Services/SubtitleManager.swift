import Foundation
import AVFoundation
import AppKit
import Combine

public struct SubtitleLanguage: Identifiable, Hashable {
    public let code: String
    public let name: String
    public var id: String { code }
    
    public init(code: String, name: String) {
        self.code = code
        self.name = name
    }
}

public final class SubtitleManager: ObservableObject {
    public static let shared = SubtitleManager()
    
    @Published public var activeSubtitleText: String? = nil
    @Published public var availableSubtitleTracks: [MediaTrackOption] = []
    @Published public var selectedSubtitleTrackId: String = "off"
    
    @Published public var availableAudioTracks: [MediaTrackOption] = []
    @Published public var selectedAudioTrackId: String = "default"
    
    @Published public var targetLanguage: String = "original"
    @Published public var isTranslating: Bool = false
    
    public static let supportedLanguages: [SubtitleLanguage] = [
        SubtitleLanguage(code: "original", name: "Original (No Translation)"),
        SubtitleLanguage(code: "it", name: "Italian (Italiano)"),
        SubtitleLanguage(code: "en", name: "English"),
        SubtitleLanguage(code: "es", name: "Spanish (Español)"),
        SubtitleLanguage(code: "fr", name: "French (Français)"),
        SubtitleLanguage(code: "de", name: "German (Deutsch)"),
        SubtitleLanguage(code: "pt", name: "Portuguese (Português)"),
        SubtitleLanguage(code: "ja", name: "Japanese (日本語)"),
        SubtitleLanguage(code: "zh", name: "Chinese (中文)")
    ]
    
    private var externalCues: [SubtitleCue] = []
    private var translatedCuesCache: [String: String] = [:] // key: "\(cueId)_\(langCode)"
    private weak var player: AVPlayer?
    private var currentAsset: AVAsset?
    
    public init() {}
    
    public func attach(player: AVPlayer) {
        self.player = player
    }
    
    // MARK: - Video Asset Update
    
    public func didLoadAsset(_ asset: AVAsset, videoURL: URL) {
        self.currentAsset = asset
        self.externalCues = []
        self.translatedCuesCache = [:]
        self.activeSubtitleText = nil
        
        loadAvailableAudioTracks(from: asset)
        loadAvailableSubtitleTracks(from: asset, videoURL: videoURL)
    }
    
    private func loadAvailableAudioTracks(from asset: AVAsset) {
        var options: [MediaTrackOption] = []
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible) {
            for (idx, option) in group.options.enumerated() {
                var name = option.displayName
                if name.isEmpty || name.lowercased().contains("unknown") {
                    name = "Audio Track \(idx + 1) (Stereo)"
                }
                let code = option.locale?.language.languageCode?.identifier ?? option.extendedLanguageTag
                options.append(MediaTrackOption(id: option.displayName, displayName: name, languageCode: code, isEmbedded: true))
            }
        }
        
        self.availableAudioTracks = options
        if let first = options.first {
            self.selectedAudioTrackId = first.id
        }
    }
    
    private func loadAvailableSubtitleTracks(from asset: AVAsset, videoURL: URL) {
        var tracks: [MediaTrackOption] = [
            MediaTrackOption(id: "off", displayName: "Off", languageCode: nil, isEmbedded: false)
        ]
        
        // 1. Embedded legible subtitles
        if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
            for (idx, option) in group.options.enumerated() {
                var name = option.displayName
                if name.isEmpty || name.lowercased().contains("unknown") {
                    name = "Subtitle Track \(idx + 1)"
                }
                let code = option.locale?.language.languageCode?.identifier ?? option.extendedLanguageTag
                tracks.append(MediaTrackOption(id: "embedded_\(name)", displayName: name, languageCode: code, isEmbedded: true))
            }
        }
        
        // 2. Check for companion subtitle files next to video: .srt, .vtt
        let videoDir = videoURL.deletingLastPathComponent()
        let baseName = videoURL.deletingPathExtension().lastPathComponent
        
        let fileManager = FileManager.default
        if let files = try? fileManager.contentsOfDirectory(atPath: videoDir.path) {
            for file in files {
                let ext = (file as NSString).pathExtension.lowercased()
                if (ext == "srt" || ext == "vtt") && file.hasPrefix(baseName) {
                    let subURL = videoDir.appendingPathComponent(file)
                    tracks.append(MediaTrackOption(id: "file_\(subURL.path)", displayName: file, languageCode: nil, isEmbedded: false))
                }
            }
        }
        
        self.availableSubtitleTracks = tracks
        
        // Auto-select first subtitle if available, otherwise off
        if tracks.count > 1 {
            selectSubtitleTrack(id: tracks[1].id)
        } else {
            self.selectedSubtitleTrackId = "off"
        }
    }
    
    // MARK: - Track Selection
    
    public func selectAudioTrack(id: String) {
        guard let asset = currentAsset,
              let group = asset.mediaSelectionGroup(forMediaCharacteristic: .audible),
              let playerItem = player?.currentItem else { return }
        
        for option in group.options {
            if option.displayName == id {
                playerItem.select(option, in: group)
                self.selectedAudioTrackId = id
                return
            }
        }
    }
    
    public func selectSubtitleTrack(id: String) {
        self.selectedSubtitleTrackId = id
        self.activeSubtitleText = nil
        AudioVoiceoverEngine.shared.stop()
        
        guard let asset = currentAsset,
              let playerItem = player?.currentItem else { return }
        
        if id == "off" {
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                playerItem.select(nil, in: group)
            }
            self.externalCues = []
            return
        }
        
        if id.hasPrefix("embedded_") {
            let trackName = String(id.dropFirst("embedded_".count))
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                for option in group.options {
                    if option.displayName == trackName {
                        playerItem.select(option, in: group)
                        self.externalCues = []
                        return
                    }
                }
            }
        } else if id.hasPrefix("file_") {
            let filePath = String(id.dropFirst("file_".count))
            loadExternalSubtitleFile(url: URL(fileURLWithPath: filePath))
            // Disable embedded
            if let group = asset.mediaSelectionGroup(forMediaCharacteristic: .legible) {
                playerItem.select(nil, in: group)
            }
        }
    }
    
    public func loadExternalSubtitleFile(url: URL) {
        guard let content = (try? String(contentsOf: url, encoding: .utf8)) ?? (try? String(contentsOf: url, encoding: .isoLatin1)) else {
            return
        }
        self.externalCues = SRTParser.parse(content: content)
        self.translatedCuesCache.removeAll()
        AudioVoiceoverEngine.shared.stop()
        
        // Register in tracks if not present
        let trackId = "file_\(url.path)"
        if !availableSubtitleTracks.contains(where: { $0.id == trackId }) {
            availableSubtitleTracks.append(MediaTrackOption(id: trackId, displayName: url.lastPathComponent, languageCode: nil, isEmbedded: false))
        }
        self.selectedSubtitleTrackId = trackId
    }
    
    // MARK: - Time Update & Subtitle Display
    
    public func updateTime(_ currentTime: Double) {
        guard selectedSubtitleTrackId != "off", !externalCues.isEmpty else {
            return
        }
        
        // Find matching cue for current timestamp
        if let match = externalCues.first(where: { $0.startTime <= currentTime && currentTime <= $0.endTime }) {
            if targetLanguage == "original" {
                if self.activeSubtitleText != match.text {
                    self.activeSubtitleText = match.text
                    if AudioVoiceoverEngine.shared.isVoiceoverEnabled {
                        AudioVoiceoverEngine.shared.speakCue(text: match.text, languageCode: "en")
                    }
                }
            } else {
                let cacheKey = "\(match.id)_\(targetLanguage)"
                if let cached = translatedCuesCache[cacheKey] {
                    if self.activeSubtitleText != cached {
                        self.activeSubtitleText = cached
                        if AudioVoiceoverEngine.shared.isVoiceoverEnabled {
                            AudioVoiceoverEngine.shared.speakCue(text: cached, languageCode: targetLanguage)
                        }
                    }
                } else {
                    self.activeSubtitleText = match.text
                    translateCue(match, to: targetLanguage)
                }
            }
        } else {
            self.activeSubtitleText = nil
        }
    }
    
    // MARK: - Subtitle Translation (Fast API with Memory Caching)
    
    public func setTargetLanguage(_ lang: String) {
        self.targetLanguage = lang
        self.activeSubtitleText = nil
        AudioVoiceoverEngine.shared.stop()
    }
    
    private func translateCue(_ cue: SubtitleCue, to lang: String) {
        let textToTranslate = cue.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !textToTranslate.isEmpty else { return }
        
        let cacheKey = "\(cue.id)_\(lang)"
        guard translatedCuesCache[cacheKey] == nil else { return }
        
        // Encode URL for MyMemory lightweight free translation endpoint
        guard let encodedText = textToTranslate.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.mymemory.translated.net/get?q=\(encodedText)&langpair=autodetect|\(lang)") else {
            return
        }
        
        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
                
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let responseData = json["responseData"] as? [String: Any],
                   let translatedText = responseData["translatedText"] as? String,
                   !translatedText.isEmpty {
                    
                    await MainActor.run {
                        self.translatedCuesCache[cacheKey] = translatedText
                        if let current = self.activeSubtitleText, current == cue.text {
                            self.activeSubtitleText = translatedText
                            if AudioVoiceoverEngine.shared.isVoiceoverEnabled {
                                AudioVoiceoverEngine.shared.speakCue(text: translatedText, languageCode: self.targetLanguage)
                            }
                        }
                    }
                }
            } catch {
                // Silently fallback to original text on network absence
            }
        }
    }
}
