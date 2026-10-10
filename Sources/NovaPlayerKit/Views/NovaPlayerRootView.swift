import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class PlayerCoordinator: ObservableObject {
    var keyHandler: KeyCommandHandler?
}

public struct NovaPlayerRootView: View {
    @ObservedObject private var state: PlayerState
    @ObservedObject private var settings = AppSettings.shared
    @StateObject private var coordinator = PlayerCoordinator()
    @ObservedObject private var subtitleManager = SubtitleManager.shared
    
    private let engine: PlaybackEngine
    private let thumbnailService: ThumbnailService
    
    public init(engine: PlaybackEngine = .shared, state: PlayerState = .shared) {
        let thumbnail = ThumbnailService()
        AudioVoiceoverEngine.shared.attach(player: engine.player)
        self.state = state
        self.engine = engine
        self.thumbnailService = thumbnail
    }
    
    public var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if state.currentURL == nil {
                // 1. Dedicated Welcome / Drag & Drop Landing Page
                WelcomeLandingView(
                    onOpenFile: openFileDialog,
                    onFileDropped: openFile,
                    onCloseWindow: closeWindow,
                    onMinimizeWindow: minimizeWindow,
                    onToggleFullscreen: toggleFullscreen
                )
                .transition(.opacity)
            } else {
                // 2. Active Video Playback Visualization
                ZStack {
                    // Video Surface Layer
                    VideoSurfaceView(
                        player: engine.player,
                        state: state,
                        engine: engine,
                        thumbnailService: thumbnailService,
                        settings: settings,
                        onToggleFullscreen: toggleFullscreen
                    )
                    .ignoresSafeArea()
                    
                    // Subtitle Display Layer
                    SubtitleOverlayView(subtitleManager: subtitleManager)
                        .ignoresSafeArea()
                    
                    // UI Controls Overlay Layer
                    ControlsOverlayView(
                        state: state,
                        engine: engine,
                        thumbnailService: thumbnailService,
                        settings: settings,
                        onOpenFile: openFileDialog,
                        onOpenSubtitleFile: openSubtitleFileDialog,
                        onToggleFullscreen: toggleFullscreen,
                        onCloseWindow: closeWindow,
                        onMinimizeWindow: minimizeWindow,
                        onCloseVideo: closeCurrentVideo
                    )
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: state.currentURL != nil)
        .frame(minWidth: 540, minHeight: 340)
        .onAppear {
            if coordinator.keyHandler == nil {
                coordinator.keyHandler = KeyCommandHandler(
                    engine: engine,
                    state: state,
                    settings: settings,
                    onOpenFile: openFileDialog,
                    onToggleFullscreen: toggleFullscreen
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            state.isFullscreen = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            state.isFullscreen = false
        }
    }
    
    // MARK: - Actions
    
    public func openFile(url: URL) {
        engine.loadVideo(url: url)
        thumbnailService.setAsset(url: url)
    }
    
    private func closeCurrentVideo() {
        engine.closeVideo()
    }
    
    private func openFileDialog() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType.mpeg4Movie,
            UTType.quickTimeMovie,
            UTType(filenameExtension: "m4v") ?? .movie
        ]
        
        if panel.runModal() == .OK, let url = panel.url {
            openFile(url: url)
        }
    }
    
    private func openSubtitleFileDialog() {
        let panel = NSOpenPanel()
        panel.title = "Choose Subtitle File"
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        
        let srtType = UTType(filenameExtension: "srt") ?? .text
        let vttType = UTType(filenameExtension: "vtt") ?? .text
        panel.allowedContentTypes = [srtType, vttType, .text]
        
        if panel.runModal() == .OK, let url = panel.url {
            subtitleManager.loadExternalSubtitleFile(url: url)
            state.showHUD(text: "Subtitles Loaded", icon: "captions.bubble.fill")
        }
    }
    
    private func toggleFullscreen() {
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            window.toggleFullScreen(nil)
        }
    }
    
    private func closeWindow() {
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            window.close()
        }
    }
    
    private func minimizeWindow() {
        if let window = NSApplication.shared.keyWindow ?? NSApplication.shared.windows.first {
            window.miniaturize(nil)
        }
    }
}
