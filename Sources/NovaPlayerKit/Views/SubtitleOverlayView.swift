import SwiftUI

public struct SubtitleOverlayView: View {
    @ObservedObject var subtitleManager: SubtitleManager
    
    public init(subtitleManager: SubtitleManager = .shared) {
        self.subtitleManager = subtitleManager
    }
    
    public var body: some View {
        VStack {
            Spacer()
            if let text = subtitleManager.activeSubtitleText, !text.isEmpty {
                Text(text)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.black.opacity(0.75))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                    .padding(.bottom, 70) // Positioned above the bottom scrubber bar
                    .transition(.opacity)
            }
        }
        .allowsHitTesting(false) // Never block clicks to the player
        .animation(.easeInOut(duration: 0.15), value: subtitleManager.activeSubtitleText)
    }
}
