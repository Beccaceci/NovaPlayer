import Testing
import Foundation
import AVFoundation
@testable import NovaPlayerKit

private final class ControlledTranslator: SubtitleTranslating {
    var calls = 0
    var continuation: CheckedContinuation<String, Error>?
    func translate(_ text: String, from source: String, to language: String) async throws -> String {
        calls += 1
        return try await withCheckedThrowingContinuation { continuation = $0 }
    }
}

final class SubtitleTests {
    @Test @MainActor func testCueBoundariesOffAndReset() {
        let manager = SubtitleManager()
        manager.loadExternalSubtitleFile(url: fixture("sample", "srt"))
        manager.updateTime(0)
        #expect(manager.activeSubtitleText == nil)
        manager.updateTime(1)
        #expect(manager.activeSubtitleText == "Hello world")
        manager.updateTime(2)
        #expect(manager.activeSubtitleText == "Second line")
        manager.updateTime(4)
        #expect(manager.activeSubtitleText == nil)
        manager.selectSubtitleTrack(id: "off")
        manager.updateTime(1)
        #expect(manager.activeSubtitleText == nil)
        manager.reset()
        #expect(manager.selectedAudioTrackId == "default")
    }
    @Test @MainActor func testDeduplicatesAndRejectsStaleTranslation() async throws {
        let translator = ControlledTranslator()
        let manager = SubtitleManager(translator: translator)
        manager.loadExternalSubtitleFile(url: fixture("sample", "srt"))
        manager.setTargetLanguage("it")
        for _ in 0..<30 { manager.updateTime(1.5) }
        try await eventually { translator.calls == 1 }
        #expect(translator.calls == 1)
        #expect(manager.isTranslating)
        manager.setTargetLanguage("fr")
        translator.continuation?.resume(returning: "Ciao")
        await Task.yield()
        #expect(manager.activeSubtitleText == nil)
        #expect(!(manager.isTranslating))
    }
    @Test @MainActor func testTranslationFailureDoesNotRetryEveryTick() async throws {
        let translator = ControlledTranslator()
        let manager = SubtitleManager(translator: translator)
        manager.loadExternalSubtitleFile(url: fixture("sample", "srt"))
        manager.setTargetLanguage("it")
        manager.updateTime(1)
        try await eventually { translator.calls == 1 }
        translator.continuation?.resume(throwing: URLError(.notConnectedToInternet))
        try await eventually { !manager.isTranslating }
        for _ in 0..<30 { manager.updateTime(1) }
        #expect(translator.calls == 1)
        #expect(manager.activeSubtitleText == "Hello world")
        #expect(manager.translationError != nil)
    }
    @Test @MainActor func testSuccessfulTranslationIsCached() async throws {
        let translator = ControlledTranslator()
        let manager = SubtitleManager(translator: translator)
        manager.loadExternalSubtitleFile(url: fixture("sample", "srt"))
        manager.setTargetLanguage("it")
        manager.updateTime(1)
        try await eventually { translator.calls == 1 }
        translator.continuation?.resume(returning: "Ciao mondo")
        try await eventually { !manager.isTranslating }
        #expect(manager.activeSubtitleText == "Ciao mondo")
        manager.updateTime(0)
        manager.updateTime(1)
        #expect(manager.activeSubtitleText == "Ciao mondo")
        #expect(translator.calls == 1)
    }

    @Test @MainActor func testSidecarDiscoveryRejectsUnrelatedPrefix() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        for name in ["film.en.srt", "film2.srt", "film.vtt"] {
            try "".write(to: dir.appendingPathComponent(name), atomically: true, encoding: .utf8)
        }
        let manager = SubtitleManager()
        let url = dir.appendingPathComponent("film.mp4")
        manager.didLoadAsset(AVURLAsset(url: url), videoURL: url)
        #expect(manager.availableSubtitleTracks.map(\.displayName) == ["Off", "film.en.srt", "film.vtt"])
    }
}
