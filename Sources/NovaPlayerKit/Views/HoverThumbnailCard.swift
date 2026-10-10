import SwiftUI
import AppKit

public struct HoverThumbnailCard: View {
    let image: NSImage?
    let timestamp: Double
    let totalDuration: Double
    let isLoading: Bool
    
    public init(image: NSImage?, timestamp: Double, totalDuration: Double, isLoading: Bool = false) {
        self.image = image
        self.timestamp = timestamp
        self.totalDuration = totalDuration
        self.isLoading = isLoading
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.85))
                
                if let image = image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 192, height: 108)
                        .clipped()
                        .cornerRadius(8)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "film")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.4))
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .colorScheme(.dark)
                        }
                    }
                    .frame(width: 192, height: 108)
                }
            }
            .frame(width: 192, height: 108)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            
            Text(PlayerState.formatTime(timestamp))
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.8))
                )
        }
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.75))
                .shadow(color: .black.opacity(0.5), radius: 14, x: 0, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
    }
}
