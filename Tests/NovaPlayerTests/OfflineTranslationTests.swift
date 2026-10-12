import Testing
import Foundation
@testable import NovaPlayerKit

private final class RecordingProvider: SubtitleTranslating {
    var calls: [(String, String)] = []
    let result: Result<String, Error>
    init(_ result: Result<String, Error>) { self.result = result }
    func translate(_ text: String, from source: String, to language: String) async throws -> String {
        calls.append((source, language))
        return try result.get()
    }
}

struct OfflineTranslationTests {
    @Test func prefersOfflineInBothDirections() async throws {
        for (source, target) in [("en", "it"), ("it", "en")] {
            let offline = RecordingProvider(.success("local"))
            let online = RecordingProvider(.success("remote"))
            let router = OfflineFirstTranslator(offline: offline, online: online)
            let result = try await router.translate("text", from: source, to: target)
            #expect(result == "local")
            #expect(offline.calls.first?.0 == source)
            #expect(offline.calls.first?.1 == target)
            #expect(online.calls.isEmpty)
        }
    }
    @Test func fallsBackWhenLocalResourcesAreUnavailable() async throws {
        let offline = RecordingProvider(.failure(OfflineTranslationError.unavailable))
        let online = RecordingProvider(.success("remote"))
        let result = try await OfflineFirstTranslator(offline: offline, online: online)
            .translate("text", from: "it", to: "en")
        #expect(result == "remote")
        #expect(online.calls.count == 1)
    }
    @Test func offlineOnlyNeverCallsOnline() async {
        let offline = RecordingProvider(.failure(OfflineTranslationError.unavailable))
        let online = RecordingProvider(.success("remote"))
        do {
            _ = try await OfflineFirstTranslator(offline: offline, online: online)
                .translate("text", from: "en", to: "it", allowOnline: false)
            Issue.record("Expected unavailable offline translation")
        } catch { #expect(online.calls.isEmpty) }
    }
    @Test func cancellationNeverFallsBack() async {
        let offline = RecordingProvider(.failure(CancellationError()))
        let online = RecordingProvider(.success("remote"))
        do {
            _ = try await OfflineFirstTranslator(offline: offline, online: online)
                .translate("text", from: "en", to: "it")
            Issue.record("Expected cancellation")
        } catch { #expect(error is CancellationError) }
        #expect(online.calls.isEmpty)
    }
    @Test func sameLanguageSkipsBothProviders() async throws {
        let provider = RecordingProvider(.success("unexpected"))
        let result = try await OfflineFirstTranslator(offline: provider, online: provider)
            .translate("Hello", from: "en", to: "en")
        #expect(result == "Hello")
        #expect(provider.calls.isEmpty)
    }
    @Test @MainActor func sourceAndPolicyChangesClearDisplayedTranslation() {
        let manager = SubtitleManager()
        manager.loadExternalSubtitleFile(url: fixture("sample", "srt"))
        manager.updateTime(1)
        #expect(manager.activeSubtitleText != nil)
        manager.setSourceLanguage("it")
        #expect(manager.sourceLanguage == "it")
        #expect(manager.activeSubtitleText == nil)
        manager.setAllowsOnlineFallback(false)
        #expect(!manager.allowsOnlineFallback)
        manager.setSourceLanguage("invalid")
        #expect(manager.sourceLanguage == "it")
    }
}
