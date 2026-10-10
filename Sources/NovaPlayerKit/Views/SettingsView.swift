import SwiftUI

public struct SettingsView: View {
    @ObservedObject var settings: AppSettings
    @Binding var isPresented: Bool
    
    public init(settings: AppSettings = .shared, isPresented: Binding<Bool>) {
        self.settings = settings
        self._isPresented = isPresented
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("NovaPlayer Settings")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: { isPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Skip Interval
            VStack(alignment: .leading, spacing: 6) {
                Text("Skip Forward / Backward")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Skip Duration", selection: $settings.skipInterval) {
                    ForEach(AppSettings.availableSkipIntervals, id: \.self) { sec in
                        Text("\(Int(sec))s").tag(sec)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }
            
            // Speed Granularity
            VStack(alignment: .leading, spacing: 6) {
                Text("Speed Step Increment")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Granularity", selection: $settings.speedGranularity) {
                    ForEach(AppSettings.availableSpeedGranularities, id: \.self) { step in
                        Text(String(format: "%.2f×", step)).tag(step)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                
                Text("Increment when pressing [ and ] or clicking speed buttons.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Hover Previews
            Toggle(isOn: $settings.hoverPreviewEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Timeline Frame Previews")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Text("Show preview thumbnails when hovering over the timeline.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            
            // Auto-hide delay
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Auto-Hide Controls Delay")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.1fs", settings.autoHideDelay))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Slider(value: $settings.autoHideDelay, in: 1.0...5.0, step: 0.5)
            }
        }
        .padding(16)
        .frame(width: 280)
    }
}
