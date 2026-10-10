import Foundation
import AppKit
import Combine

public struct HUDNotice: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let iconName: String
    
    public init(text: String, iconName: String) {
        self.text = text
        self.iconName = iconName
    }
}

public struct HoverPreviewState: Equatable {
    public var isHovering: Bool = false
    public var hoverTime: Double = 0
    public var normalizedX: CGFloat = 0
    public var thumbnailImage: NSImage? = nil
    public var isLoading: Bool = false
    
    public init() {}
}

public final class PlayerState: ObservableObject {
    public static let shared = PlayerState()
    
    @Published public var currentURL: URL? = nil
    @Published public var videoTitle: String = "No Video Loaded"
    
    @Published public var isPlaying: Bool = false
    @Published public var isBuffering: Bool = false
    @Published public var currentTime: Double = 0.0
    @Published public var duration: Double = 0.0
    
    @Published public var playbackRate: Float = 1.0
    @Published public var volume: Float = 1.0
    @Published public var isMuted: Bool = false
    
    @Published public var hoverPreview = HoverPreviewState()
    @Published public var hudNotice: HUDNotice? = nil
    @Published public var controlsVisible: Bool = true
    @Published public var isFullscreen: Bool = false
    
    private var hudDismissWorkItem: DispatchWorkItem?
    
    public init() {}
    
    public var progress: Double {
        guard duration > 0 else { return 0 }
        return min(max(currentTime / duration, 0.0), 1.0)
    }
    
    public func formattedPlaybackRate() -> String {
        return String(format: "%.2f×", playbackRate)
    }
    
    public static func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && !seconds.isInfinite && seconds >= 0 else {
            return "0:00"
        }
        let totalSeconds = Int(seconds)
        let s = totalSeconds % 60
        let m = (totalSeconds / 60) % 60
        let h = totalSeconds / 3600
        
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%d:%02d", m, s)
        }
    }
    
    public func showHUD(text: String, icon: String, duration: Double = 1.0) {
        hudDismissWorkItem?.cancel()
        
        let notice = HUDNotice(text: text, iconName: icon)
        self.hudNotice = notice
        
        let work = DispatchWorkItem { [weak self] in
            if self?.hudNotice?.id == notice.id {
                self?.hudNotice = nil
            }
        }
        hudDismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }
}
