import SwiftUI
import Translation

@available(macOS 15, *)
private final class OfflinePreparationState: ObservableObject {
    @Published var configuration: TranslationSession.Configuration?
    @Published var message = "Download language resources once to use offline translation."
    @Published var preparing = false
}

/// Kept in the popover only for preparation; playback uses independent sessions.
@available(macOS 15, *)
struct OfflineTranslationSetupView: View {
    let source: String
    let target: String
    let onPrepared: () -> Void
    @StateObject private var state = OfflinePreparationState()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button(state.preparing ? "Preparing languages…" : "Prepare offline translation") {
                state.preparing = true
                state.message = "Keep this menu open while preparing languages."
                if state.configuration == nil {
                    #if compiler(>=6.3)
                    if #available(macOS 26.4, *) {
                        state.configuration = .init(source: Locale.Language(identifier: source),
                                                    target: Locale.Language(identifier: target),
                                                    preferredStrategy: .lowLatency)
                    } else {
                        state.configuration = .init(source: Locale.Language(identifier: source),
                                                    target: Locale.Language(identifier: target))
                    }
                    #else
                    state.configuration = .init(source: Locale.Language(identifier: source),
                                                target: Locale.Language(identifier: target))
                    #endif
                } else {
                    state.configuration?.invalidate()
                }
            }
            .disabled(state.preparing)
            Text(state.message).font(.caption2).foregroundColor(.secondary)
        }
        .translationTask(state.configuration) { session in
            do {
                try await session.prepareTranslation()
                state.message = "Language resources ready for offline translation."
                onPrepared()
            } catch {
                state.message = "Could not prepare languages. Check your connection and try again."
            }
            state.preparing = false
        }
    }
}
