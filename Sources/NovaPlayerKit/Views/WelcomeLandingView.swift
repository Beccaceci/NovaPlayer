import SwiftUI
import AppKit
import UniformTypeIdentifiers

final class WelcomeViewModel: ObservableObject {
    @Published var isDropTargeted: Bool = false
}

public struct WelcomeLandingView: View {
    let onOpenFile: () -> Void
    let onFileDropped: (URL) -> Void
    let onCloseWindow: () -> Void
    let onMinimizeWindow: () -> Void
    let onToggleFullscreen: () -> Void
    
    @StateObject private var vm = WelcomeViewModel()
    
    public init(
        onOpenFile: @escaping () -> Void,
        onFileDropped: @escaping (URL) -> Void,
        onCloseWindow: @escaping () -> Void,
        onMinimizeWindow: @escaping () -> Void,
        onToggleFullscreen: @escaping () -> Void
    ) {
        self.onOpenFile = onOpenFile
        self.onFileDropped = onFileDropped
        self.onCloseWindow = onCloseWindow
        self.onMinimizeWindow = onMinimizeWindow
        self.onToggleFullscreen = onToggleFullscreen
    }
    
    public var body: some View {
        ZStack {
            // Dark gradient backdrop
            LinearGradient(
                colors: [Color(red: 0.07, green: 0.08, blue: 0.12), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                // Top Bar with Window Traffic Lights
                HStack(spacing: 8) {
                    Button(action: onCloseWindow) {
                        Circle()
                            .fill(Color.red.opacity(0.9))
                            .frame(width: 13, height: 13)
                            .overlay(Image(systemName: "xmark").font(.system(size: 7, weight: .bold)).foregroundColor(.black.opacity(0.6)))
                    }
                    .buttonStyle(.plain)
                    .help("Close Window")
                    
                    Button(action: onMinimizeWindow) {
                        Circle()
                            .fill(Color.yellow.opacity(0.9))
                            .frame(width: 13, height: 13)
                            .overlay(Image(systemName: "minus").font(.system(size: 7, weight: .bold)).foregroundColor(.black.opacity(0.6)))
                    }
                    .buttonStyle(.plain)
                    .help("Minimize Window")
                    
                    Button(action: onToggleFullscreen) {
                        Circle()
                            .fill(Color.green.opacity(0.9))
                            .frame(width: 13, height: 13)
                            .overlay(Image(systemName: "arrow.up.left.and.arrow.down.right").font(.system(size: 6, weight: .bold)).foregroundColor(.black.opacity(0.7)))
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Fullscreen (F)")
                    
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
                
                // Center Hero Content
                VStack(spacing: 24) {
                    // App Logo with Cosmic Glow
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.blue.opacity(0.35), Color.purple.opacity(0.15), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 75
                                )
                            )
                            .frame(width: 130, height: 130)
                        
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(red: 0.16, green: 0.18, blue: 0.28), Color(red: 0.08, green: 0.09, blue: 0.16)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 84, height: 84)
                            .overlay(
                                RoundedRectangle(cornerRadius: 22, style: .continuous)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.blue.opacity(0.4), radius: 16, x: 0, y: 8)
                        
                        Image(systemName: "play.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .offset(x: 2)
                    }
                    
                    // Title and Description
                    VStack(spacing: 6) {
                        Text("NovaPlayer")
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("High-performance media player with YouTube-like ergonomics")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    
                    // Drop Zone Card
                    VStack(spacing: 14) {
                        Image(systemName: vm.isDropTargeted ? "arrow.down.circle.fill" : "film")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(vm.isDropTargeted ? .accentColor : .white.opacity(0.6))
                            .animation(.spring(response: 0.3), value: vm.isDropTargeted)
                        
                        Text(vm.isDropTargeted ? "Drop Video to Play" : "Drag and drop any MP4, MOV, or M4V video here")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(vm.isDropTargeted ? .white : .white.opacity(0.8))
                        
                        Text("or")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.4))
                        
                        Button(action: onOpenFile) {
                            HStack(spacing: 8) {
                                Image(systemName: "folder.fill")
                                Text("Choose Video File…")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.blue.opacity(0.85))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Open Video File (Cmd+O)")
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 28)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.white.opacity(vm.isDropTargeted ? 0.10 : 0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                vm.isDropTargeted ? Color.blue : Color.white.opacity(0.18),
                                style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])
                            )
                    )
                    .frame(maxWidth: 440)
                    .onDrop(of: [.fileURL], isTargeted: Binding(get: { vm.isDropTargeted }, set: { vm.isDropTargeted = $0 })) { providers in
                        guard let provider = providers.first else { return false }
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                DispatchQueue.main.async {
                                    onFileDropped(url)
                                }
                            }
                        }
                        return true
                    }
                    
                    // Feature Badges
                    HStack(spacing: 12) {
                        featureBadge(icon: "gauge.with.needle.fill", text: "0.05× Speed")
                        featureBadge(icon: "goforward.5", text: "5s Skips")
                        featureBadge(icon: "photo.stack", text: "Hover Scrubber")
                        featureBadge(icon: "captions.bubble.fill", text: "Subtitles & Dubbing")
                    }
                    .padding(.top, 6)
                }
                
                Spacer()
                
                Text("Press Cmd+O to open a file anytime")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.35))
                    .padding(.bottom, 16)
            }
        }
    }
    
    private func featureBadge(icon: String, text: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text(text)
                .font(.system(size: 11, weight: .medium))
        }
        .foregroundColor(.white.opacity(0.6))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }
}
