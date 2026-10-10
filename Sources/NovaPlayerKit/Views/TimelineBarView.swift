import SwiftUI
import AppKit

final class TimelineViewModel: ObservableObject {
    @Published var isDragging: Bool = false
    @Published var dragProgress: Double = 0.0
    @Published var isBarHovered: Bool = false
}

public struct TimelineBarView: View {
    @ObservedObject var state: PlayerState
    let engine: PlaybackEngine
    let thumbnailService: ThumbnailService
    @ObservedObject var settings: AppSettings
    
    @StateObject private var vm = TimelineViewModel()
    
    public init(state: PlayerState, engine: PlaybackEngine, thumbnailService: ThumbnailService, settings: AppSettings = .shared) {
        self.state = state
        self.engine = engine
        self.thumbnailService = thumbnailService
        self.settings = settings
    }
    
    public var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let currentProgress = vm.isDragging ? vm.dragProgress : state.progress
            let trackHeight: CGFloat = (vm.isBarHovered || vm.isDragging) ? 8 : 5
            
            ZStack(alignment: .bottomLeading) {
                // Hover Thumbnail Card (floats above the bar)
                if settings.hoverPreviewEnabled && state.hoverPreview.isHovering && state.duration > 0 {
                    let cardWidth: CGFloat = 208
                    let hoverX = state.hoverPreview.normalizedX * totalWidth
                    let clampedX = min(max(hoverX, cardWidth / 2 + 4), totalWidth - (cardWidth / 2 + 4))
                    
                    HoverThumbnailCard(
                        image: state.hoverPreview.thumbnailImage,
                        timestamp: state.hoverPreview.hoverTime,
                        totalDuration: state.duration,
                        isLoading: state.hoverPreview.isLoading
                    )
                    .position(x: clampedX, y: -75)
                }
                
                // Track layers container
                ZStack(alignment: .leading) {
                    // Base background track
                    Capsule()
                        .fill(Color.white.opacity(0.25))
                        .frame(height: trackHeight)
                    
                    // Hover highlight track
                    if state.hoverPreview.isHovering {
                        Capsule()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: max(0, min(state.hoverPreview.normalizedX * totalWidth, totalWidth)), height: trackHeight)
                    }
                    
                    // Progress played track
                    Capsule()
                        .fill(Color.red)
                        .frame(width: max(0, min(CGFloat(currentProgress) * totalWidth, totalWidth)), height: trackHeight)
                    
                    // Scrubber knob
                    Circle()
                        .fill(Color.white)
                        .frame(width: (vm.isBarHovered || vm.isDragging) ? 14 : 0, height: (vm.isBarHovered || vm.isDragging) ? 14 : 0)
                        .shadow(color: .black.opacity(0.4), radius: 3, x: 0, y: 1)
                        .offset(x: max(0, min(CGFloat(currentProgress) * totalWidth - 7, totalWidth - 14)))
                }
                .frame(height: 20)
                .contentShape(Rectangle())
                // Hover detection
                .onContinuousHover { phase in
                    guard settings.hoverPreviewEnabled else { return }
                    switch phase {
                    case .active(let location):
                        vm.isBarHovered = true
                        let fraction = min(max(location.x / totalWidth, 0.0), 1.0)
                        let time = fraction * state.duration
                        
                        state.hoverPreview.isHovering = true
                        state.hoverPreview.normalizedX = fraction
                        state.hoverPreview.hoverTime = time
                        state.hoverPreview.isLoading = true
                        
                        thumbnailService.requestThumbnail(at: time) { image in
                            if self.state.hoverPreview.isHovering {
                                if let image = image {
                                    self.state.hoverPreview.thumbnailImage = image
                                    self.state.hoverPreview.isLoading = false
                                }
                            }
                        }
                    case .ended:
                        vm.isBarHovered = false
                        state.hoverPreview.isHovering = false
                        state.hoverPreview.thumbnailImage = nil
                        thumbnailService.cancel()
                    }
                }
                // Drag / Click scrubbing gesture
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            vm.isDragging = true
                            let fraction = min(max(value.location.x / totalWidth, 0.0), 1.0)
                            vm.dragProgress = fraction
                            engine.seekToFraction(fraction, precise: false)
                        }
                        .onEnded { value in
                            let fraction = min(max(value.location.x / totalWidth, 0.0), 1.0)
                            vm.dragProgress = fraction
                            engine.seekToFraction(fraction, precise: true)
                            vm.isDragging = false
                        }
                )
            }
        }
        .frame(height: 20)
        .animation(.easeInOut(duration: 0.15), value: vm.isBarHovered)
        .animation(.easeInOut(duration: 0.15), value: vm.isDragging)
    }
}
