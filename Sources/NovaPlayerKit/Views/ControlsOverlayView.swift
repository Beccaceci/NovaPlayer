import SwiftUI
import AppKit

final class ControlsOverlayViewModel: ObservableObject {
    @Published var isShowingSettings: Bool = false
    @Published var isHoveringVolume: Bool = false
}

public struct ControlsOverlayView: View {
    @ObservedObject var state: PlayerState
    let engine: PlaybackEngine
    let thumbnailService: ThumbnailService
    @ObservedObject var settings: AppSettings
    
    let onOpenFile: () -> Void
    let onOpenSubtitleFile: () -> Void
    let onToggleFullscreen: () -> Void
    let onCloseWindow: () -> Void
    let onMinimizeWindow: () -> Void
    let onCloseVideo: () -> Void
    
    @StateObject private var vm = ControlsOverlayViewModel()
    
    public init(
        state: PlayerState,
        engine: PlaybackEngine,
        thumbnailService: ThumbnailService,
        settings: AppSettings = .shared,
        onOpenFile: @escaping () -> Void,
        onOpenSubtitleFile: @escaping () -> Void,
        onToggleFullscreen: @escaping () -> Void,
        onCloseWindow: @escaping () -> Void,
        onMinimizeWindow: @escaping () -> Void,
        onCloseVideo: @escaping () -> Void
    ) {
        self.state = state
        self.engine = engine
        self.thumbnailService = thumbnailService
        self.settings = settings
        self.onOpenFile = onOpenFile
        self.onOpenSubtitleFile = onOpenSubtitleFile
        self.onToggleFullscreen = onToggleFullscreen
        self.onCloseWindow = onCloseWindow
        self.onMinimizeWindow = onMinimizeWindow
        self.onCloseVideo = onCloseVideo
    }
    
    public var body: some View {
        ZStack {
            // Center HUD Notification
            if let notice = state.hudNotice {
                HUDIndicatorView(notice: notice)
            }
            
            // Floating Cinema Controls (Fade in/out on hover)
            VStack {
                // Top Bar
                topBar
                    .opacity(state.controlsVisible || vm.isShowingSettings ? 1.0 : 0.0)
                
                Spacer()
                
                // Bottom Bar
                bottomBar
                    .opacity(state.controlsVisible || vm.isShowingSettings ? 1.0 : 0.0)
            }
            .animation(.easeInOut(duration: 0.25), value: state.controlsVisible)
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 16) {
            // Window control buttons (cinema style traffic lights with Green enabled)
            HStack(spacing: 8) {
                // Red: Close
                Button(action: onCloseWindow) {
                    Circle()
                        .fill(Color.red.opacity(0.9))
                        .frame(width: 13, height: 13)
                        .overlay(Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(.black.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .help("Close Window")
                
                // Yellow: Minimize
                Button(action: onMinimizeWindow) {
                    Circle()
                        .fill(Color.yellow.opacity(0.9))
                        .frame(width: 13, height: 13)
                        .overlay(Image(systemName: "minus").font(.system(size: 7, weight: .bold)).foregroundColor(.black.opacity(0.6)))
                }
                .buttonStyle(.plain)
                .help("Minimize Window")
                
                // Green: Fullscreen / Zoom
                Button(action: onToggleFullscreen) {
                    Circle()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: 13, height: 13)
                        .overlay(
                            Image(systemName: state.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 6, weight: .bold))
                                .foregroundColor(.black.opacity(0.7))
                        )
                }
                .buttonStyle(.plain)
                .help("Toggle Fullscreen (F)")
                
                // Back to Home button
                Button(action: onCloseVideo) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 10, weight: .bold))
                        Text("Home")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .help("Close Video and Return to Home")
                .accessibilityIdentifier("closeVideo")
            }
            
            // Video Title
            Text(state.videoTitle)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            // Top Right Actions
            HStack(spacing: 14) {
                Button(action: onOpenFile) {
                    Image(systemName: "folder")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .help("Open Video File (Cmd+O)")
                
                Button(action: { vm.isShowingSettings.toggle() }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .help("Preferences")
                .popover(isPresented: $vm.isShowingSettings, arrowEdge: .bottom) {
                    SettingsView(settings: settings, isPresented: $vm.isShowingSettings)
                }
                
                Button(action: onToggleFullscreen) {
                    Image(systemName: state.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .help("Toggle Fullscreen (F)")
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.7), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Bottom Bar
    private var bottomBar: some View {
        VStack(spacing: 10) {
            // Scrubber Timeline with Frame Hover Preview
            TimelineBarView(
                state: state,
                engine: engine,
                thumbnailService: thumbnailService,
                settings: settings
            )
            .padding(.horizontal, 20)
            
            // Controls row
            HStack(spacing: 16) {
                // Play / Pause
                Button(action: { engine.togglePlayPause() }) {
                    Image(systemName: state.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
                
                .accessibilityIdentifier("playPause")
                .accessibilityLabel(state.isPlaying ? "Pause" : "Play")

                // Skip Backward
                Button(action: { engine.skipBackward() }) {
                    HStack(spacing: 1) {
                        Image(systemName: "gobackward")
                        Text("\(Int(settings.skipInterval))")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Skip backward \(Int(settings.skipInterval))s (Left Arrow / J)")
                
                // Skip Forward
                Button(action: { engine.skipForward() }) {
                    HStack(spacing: 1) {
                        Image(systemName: "goforward")
                        Text("\(Int(settings.skipInterval))")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Skip forward \(Int(settings.skipInterval))s (Right Arrow / L)")
                
                // Volume Group
                HStack(spacing: 6) {
                    Button(action: { engine.toggleMute() }) {
                        Image(systemName: state.isMuted || state.volume == 0 ? "speaker.slash.fill" : (state.volume > 0.5 ? "speaker.wave.3.fill" : "speaker.wave.1.fill"))
                            .font(.system(size: 15))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .buttonStyle(.plain)
                    .help("Mute / Unmute (M)")
                    .accessibilityIdentifier("mute")
                    .accessibilityLabel(state.isMuted ? "Unmute" : "Mute")
                    
                    Slider(
                        value: Binding(
                            get: { Double(state.isMuted ? 0 : state.volume) },
                            set: { engine.setVolume(Float($0)) }
                        ),
                        in: 0...1
                    )
                    .frame(width: 70)
                    .accentColor(.white)
                }
                
                // Time Readout
                HStack(spacing: 4) {
                    Text(PlayerState.formatTime(state.currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                    Text("/")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                    Text(PlayerState.formatTime(state.duration))
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .foregroundColor(.white)
                
                Spacer()
                
                // Audio & Subtitles Menu
                TrackSelectionPopover(subtitleManager: engine.subtitles, onOpenSubtitleFile: onOpenSubtitleFile)
                
                // Speed Controller (0.05 granularity)
                SpeedControlPopover(state: state, engine: engine, settings: settings)
                
                // Fullscreen Button
                Button(action: onToggleFullscreen) {
                    Image(systemName: state.isFullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                .help("Fullscreen (F)")
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 16)
        .padding(.top, 24)
        .background(
            LinearGradient(
                colors: [Color.clear, Color.black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}
