import AppKit

public final class KeyCommandHandler {
    private weak var engine: PlaybackEngine?
    private weak var state: PlayerState?
    private weak var settings: AppSettings?
    private let onOpenFile: () -> Void
    private let onToggleFullscreen: () -> Void
    
    private var eventMonitor: Any?
    
    public init(
        engine: PlaybackEngine,
        state: PlayerState,
        settings: AppSettings,
        onOpenFile: @escaping () -> Void,
        onToggleFullscreen: @escaping () -> Void
    ) {
        self.engine = engine
        self.state = state
        self.settings = settings
        self.onOpenFile = onOpenFile
        self.onToggleFullscreen = onToggleFullscreen
        
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring() {
        guard eventMonitor == nil else { return }
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Check if Command modifier is pressed (e.g. Cmd+O)
            if event.modifierFlags.contains(.command) {
                if event.charactersIgnoringModifiers?.lowercased() == "o" {
                    self.onOpenFile()
                    return nil
                }
                return event
            }
            
            if self.handleKeyEvent(event) {
                return nil // Event handled, consume it
            }
            return event
        }
    }
    
    public func stopMonitoring() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        guard let chars = event.charactersIgnoringModifiers else { return false }
        
        // 1. Play / Pause
        if chars == " " || chars.lowercased() == "k" {
            engine?.togglePlayPause()
            return true
        }
        
        // 2. Seeking (Left/Right Arrows or J/L)
        if event.keyCode == 123 || chars.lowercased() == "j" { // Left Arrow or J
            engine?.skipBackward()
            return true
        }
        if event.keyCode == 124 || chars.lowercased() == "l" { // Right Arrow or L
            engine?.skipForward()
            return true
        }
        
        // 3. Playback Speed [ and ]
        if chars == "[" {
            engine?.stepRate(forward: false)
            return true
        }
        if chars == "]" {
            engine?.stepRate(forward: true)
            return true
        }
        
        // 4. Volume (Up/Down Arrow)
        if event.keyCode == 126 { // Up Arrow
            engine?.adjustVolume(by: 0.05)
            return true
        }
        if event.keyCode == 125 { // Down Arrow
            engine?.adjustVolume(by: -0.05)
            return true
        }
        
        // 5. Mute (M)
        if chars.lowercased() == "m" {
            engine?.toggleMute()
            return true
        }
        
        // 6. Fullscreen (F)
        if chars.lowercased() == "f" {
            onToggleFullscreen()
            return true
        }
        
        // 7. Numeric jumps (0 - 9)
        if let firstChar = chars.first, let digit = Int(String(firstChar)) {
            let fraction = Double(digit) * 0.10
            engine?.jumpToPercentage(fraction)
            return true
        }
        
        return false
    }
}
