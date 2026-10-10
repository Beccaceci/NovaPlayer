import SwiftUI

public struct HUDIndicatorView: View {
    let notice: HUDNotice
    
    public init(notice: HUDNotice) {
        self.notice = notice
    }
    
    public var body: some View {
        HStack(spacing: 12) {
            Image(systemName: notice.iconName)
                .font(.system(size: 28, weight: .semibold))
            Text(notice.text)
                .font(.system(size: 24, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.75))
                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .transition(.asymmetric(
            insertion: .scale(scale: 0.85).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }
}
