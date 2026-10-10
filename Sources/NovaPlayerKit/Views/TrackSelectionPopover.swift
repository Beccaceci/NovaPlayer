import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class TrackSelectionViewModel: ObservableObject {
    @Published var isShowingPopover: Bool = false
}

public struct TrackSelectionPopover: View {
    @ObservedObject var subtitleManager: SubtitleManager
    let onOpenSubtitleFile: () -> Void
    
    @StateObject private var vm = TrackSelectionViewModel()
    
    public init(subtitleManager: SubtitleManager = .shared, onOpenSubtitleFile: @escaping () -> Void) {
        self.subtitleManager = subtitleManager
        self.onOpenSubtitleFile = onOpenSubtitleFile
    }
    
    public var body: some View {
        Button(action: { vm.isShowingPopover.toggle() }) {
            Image(systemName: subtitleManager.selectedSubtitleTrackId != "off" ? "captions.bubble.fill" : "captions.bubble")
                .font(.system(size: 15))
                .foregroundColor(subtitleManager.selectedSubtitleTrackId != "off" ? .accentColor : .white.opacity(0.9))
        }
        .buttonStyle(.plain)
        .help("Subtitles & Audio Tracks")
        .popover(isPresented: $vm.isShowingPopover, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    Text("Audio & Subtitles")
                        .font(.headline)
                    Spacer()
                    Button(action: { vm.isShowingPopover = false }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
                
                // Subtitles Track
                VStack(alignment: .leading, spacing: 6) {
                    Text("Subtitles Track")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if subtitleManager.availableSubtitleTracks.isEmpty {
                        Text("No subtitle tracks available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Subtitles", selection: Binding(
                            get: { subtitleManager.selectedSubtitleTrackId },
                            set: { subtitleManager.selectSubtitleTrack(id: $0) }
                        )) {
                            ForEach(subtitleManager.availableSubtitleTracks) { track in
                                Text(track.displayName).tag(track.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    Button(action: {
                        vm.isShowingPopover = false
                        onOpenSubtitleFile()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle")
                            Text("Load Subtitles File (.srt / .vtt)…")
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 2)
                }
                
                Divider()
                
                // Subtitle Translation
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Translate Subtitles To")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Spacer()
                        if subtitleManager.targetLanguage != "original" {
                            Text("Active")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }
                    }
                    
                    Picker("Translate To", selection: Binding(
                        get: { subtitleManager.targetLanguage },
                        set: { subtitleManager.setTargetLanguage($0) }
                    )) {
                        ForEach(SubtitleManager.supportedLanguages) { lang in
                            Text(lang.name).tag(lang.code)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Text("Translates subtitles on the fly without heavy AI models.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Audio Track Selection
                VStack(alignment: .leading, spacing: 6) {
                    Text("Audio Language Track")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    if subtitleManager.availableAudioTracks.isEmpty {
                        Text("Single Audio Track (Default)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Audio Track", selection: Binding(
                            get: { subtitleManager.selectedAudioTrackId },
                            set: { subtitleManager.selectAudioTrack(id: $0) }
                        )) {
                            ForEach(subtitleManager.availableAudioTracks) { track in
                                Text(track.displayName).tag(track.id)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Divider()
                
                // Spoken Voice-Over
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(isOn: Binding(
                        get: { AudioVoiceoverEngine.shared.isVoiceoverEnabled },
                        set: { AudioVoiceoverEngine.shared.isVoiceoverEnabled = $0 }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Spoken Voice-Over Dub")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text("Speaks translated lines via macOS speech with audio ducking.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .toggleStyle(.switch)
                }
            }
            .padding(16)
            .frame(width: 300)
        }
    }
}
