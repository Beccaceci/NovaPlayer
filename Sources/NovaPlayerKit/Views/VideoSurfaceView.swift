import SwiftUI
import AppKit
import AVFoundation

public struct VideoSurfaceView: NSViewRepresentable {
    let player: AVPlayer
    let state: PlayerState
    let engine: PlaybackEngine
    let thumbnailService: ThumbnailService
    let settings: AppSettings
    let onToggleFullscreen: () -> Void
    
    public init(
        player: AVPlayer,
        state: PlayerState,
        engine: PlaybackEngine,
        thumbnailService: ThumbnailService,
        settings: AppSettings = .shared,
        onToggleFullscreen: @escaping () -> Void
    ) {
        self.player = player
        self.state = state
        self.engine = engine
        self.thumbnailService = thumbnailService
        self.settings = settings
        self.onToggleFullscreen = onToggleFullscreen
    }
    
    public func makeNSView(context: Context) -> VideoPlayerNSView {
        let view = VideoPlayerNSView(
            player: player,
            state: state,
            engine: engine,
            thumbnailService: thumbnailService,
            settings: settings,
            onToggleFullscreen: onToggleFullscreen
        )
        return view
    }
    
    public func updateNSView(_ nsView: VideoPlayerNSView, context: Context) {
        // Dynamic updates if needed
    }
}

public final class VideoPlayerNSView: NSView {
    private let playerLayer = AVPlayerLayer()
    private weak var state: PlayerState?
    private weak var engine: PlaybackEngine?
    private weak var thumbnailService: ThumbnailService?
    private weak var settings: AppSettings?
    private let onToggleFullscreen: () -> Void
    
    private var trackingArea: NSTrackingArea?
    private var autoHideWorkItem: DispatchWorkItem?
    
    public init(
        player: AVPlayer,
        state: PlayerState,
        engine: PlaybackEngine,
        thumbnailService: ThumbnailService,
        settings: AppSettings,
        onToggleFullscreen: @escaping () -> Void
    ) {
        self.state = state
        self.engine = engine
        self.thumbnailService = thumbnailService
        self.settings = settings
        self.onToggleFullscreen = onToggleFullscreen
        super.init(frame: .zero)
        
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        layer?.addSublayer(playerLayer)
        
        // Register for Drag & Drop
        registerForDraggedTypes([.fileURL])
        
        resetAutoHideTimer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func layout() {
        super.layout()
        playerLayer.frame = bounds
    }
    
    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect]
        let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(area)
        self.trackingArea = area
    }
    
    // MARK: - Mouse Movement & Auto-Hide
    
    public override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        wakeControls()
    }
    
    public override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        wakeControls()
    }
    
    public override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
    }
    
    private func wakeControls() {
        NSCursor.unhide()
        if state?.controlsVisible == false {
            state?.controlsVisible = true
        }
        resetAutoHideTimer()
    }
    
    private func resetAutoHideTimer() {
        autoHideWorkItem?.cancel()
        let delay = settings?.autoHideDelay ?? 2.5
        
        let work = DispatchWorkItem { [weak self] in
            guard let self = self, let state = self.state else { return }
            // Only hide controls if video is playing and not hovering on timeline
            if state.isPlaying && !state.hoverPreview.isHovering {
                state.controlsVisible = false
                NSCursor.setHiddenUntilMouseMoves(true)
            }
        }
        autoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }
    
    // MARK: - Double Click & Window Dragging
    
    public override func mouseDown(with event: NSEvent) {
        if event.clickCount == 2 {
            onToggleFullscreen()
            return
        }
        
        // If single click on the empty canvas, permit window drag for borderless cinema window
        window?.performDrag(with: event)
    }
    
    // MARK: - Drag and Drop File Support
    
    public override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let url = extractFileURL(from: sender) else { return [] }
        let ext = url.pathExtension.lowercased()
        if ["mp4", "mov", "m4v"].contains(ext) {
            return .copy
        }
        return []
    }
    
    public override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let url = extractFileURL(from: sender) else { return false }
        engine?.loadVideo(url: url)
        thumbnailService?.setAsset(url: url)
        return true
    }
    
    private func extractFileURL(from sender: NSDraggingInfo) -> URL? {
        guard let pasteboard = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL],
              let first = pasteboard.first else {
            return nil
        }
        return first
    }
}
