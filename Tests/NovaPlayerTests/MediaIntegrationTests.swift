import Testing
import AVFoundation
@testable import NovaPlayerKit

@Suite(.serialized) @MainActor
struct MediaIntegrationTests {
    @Test func playbackSeekSubtitleAndClose() async throws {
        let engine = makeEngine()
        defer { engine.closeVideo() }
        engine.loadVideo(url: fixture("sample", "mp4"))
        try await eventually { engine.state.duration > 0 }
        #expect(engine.player.currentItem?.status == .readyToPlay)
        try await eventually { engine.state.currentTime > 0.1 }
        engine.pause()
        engine.seek(to: 2.5)
        try await eventually { abs(engine.state.currentTime - 2.5) < 0.2 }
        #expect(engine.subtitles.activeSubtitleText == "Second line")
        engine.setRate(1.5)
        engine.play()
        #expect(engine.player.rate == 1.5)
        engine.closeVideo()
        #expect(engine.state.currentURL == nil)
        #expect(engine.state.duration == 0)
        #expect(engine.subtitles.activeSubtitleText == nil)
    }
    @Test func extractsRealThumbnailAndClearsAsset() async throws {
        let service = ThumbnailService()
        service.setAsset(url: fixture("sample", "mp4"))
        var completed = false
        var size: CGSize?
        service.requestThumbnail(at: 1) { image in
            size = image?.size
            completed = true
        }
        try await eventually { completed }
        #expect((size?.width ?? 0) > 0)
        service.reset()
        service.requestThumbnail(at: 1) { image in #expect(image == nil) }
        service.requestThumbnail(at: .nan) { image in #expect(image == nil) }
    }
    @Test func replacesAssetWithoutLeakingPreviousState() async throws {
        let engine = makeEngine()
        defer { engine.closeVideo() }
        engine.loadVideo(url: fixture("sample", "mp4"))
        engine.closeVideo()
        try await Task.sleep(for: .milliseconds(100))
        #expect(engine.state.duration == 0)
        #expect(engine.state.currentURL == nil)
        engine.loadVideo(url: fixture("sample", "mp4"))
        try await eventually { engine.state.duration > 0 }
        #expect(engine.subtitles.availableSubtitleTracks.count == 2)
    }
}

@MainActor func eventually(_ predicate: () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(8)
    while !predicate() {
        guard ContinuousClock.now < deadline else {
            Issue.record("Timed out waiting for media state")
            throw URLError(.timedOut)
        }
        try await Task.sleep(for: .milliseconds(20))
    }
}
