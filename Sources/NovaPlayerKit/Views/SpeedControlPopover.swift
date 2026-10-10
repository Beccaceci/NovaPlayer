import SwiftUI

final class SpeedControlViewModel: ObservableObject {
    @Published var isShowingPopover: Bool = false
}

public struct SpeedControlPopover: View {
    @ObservedObject var state: PlayerState
    let engine: PlaybackEngine
    @ObservedObject var settings: AppSettings
    
    @StateObject private var vm = SpeedControlViewModel()
    
    private let presets: [Float] = [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    
    public init(state: PlayerState, engine: PlaybackEngine, settings: AppSettings = .shared) {
        self.state = state
        self.engine = engine
        self.settings = settings
    }
    
    public var body: some View {
        Button(action: { vm.isShowingPopover.toggle() }) {
            Text(state.formattedPlaybackRate())
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(vm.isShowingPopover ? 0.25 : 0.15))
                )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $vm.isShowingPopover, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack {
                    Text("Playback Speed")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Spacer()
                    Text(state.formattedPlaybackRate())
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundColor(.accentColor)
                }
                
                // Granular Steppers
                HStack(spacing: 10) {
                    Button(action: { engine.stepRate(forward: false) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "minus")
                            Text(String(format: "-%.2f×", settings.speedGranularity))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { engine.setRate(1.0) }) {
                        Text("Reset (1.0×)")
                            .font(.system(size: 12, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: { engine.stepRate(forward: true) }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus")
                            Text(String(format: "+%.2f×", settings.speedGranularity))
                        }
                        .font(.system(size: 12, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
                
                // Slider
                VStack(alignment: .leading, spacing: 4) {
                    Slider(
                        value: Binding(
                            get: { Double(state.playbackRate) },
                            set: { engine.setRate(Float($0)) }
                        ),
                        in: 0.25...3.0,
                        step: Double(settings.speedGranularity)
                    )
                    
                    HStack {
                        Text("0.25×")
                        Spacer()
                        Text("1.0×")
                        Spacer()
                        Text("3.0×")
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Presets Grid
                VStack(alignment: .leading, spacing: 6) {
                    Text("Presets")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 55))], spacing: 6) {
                        ForEach(presets, id: \.self) { preset in
                            Button(action: { engine.setRate(preset) }) {
                                Text(String(format: "%.2g×", preset))
                                    .font(.system(size: 12, weight: abs(state.playbackRate - preset) < 0.01 ? .bold : .regular))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(abs(state.playbackRate - preset) < 0.01 ? Color.accentColor : Color.secondary.opacity(0.12))
                                    )
                                    .foregroundColor(abs(state.playbackRate - preset) < 0.01 ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                Text("Tip: Use [ and ] keys to adjust by \(String(format: "%.2f×", settings.speedGranularity)) anytime.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .frame(width: 280)
        }
    }
}
