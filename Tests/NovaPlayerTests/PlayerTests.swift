import Testing
import Foundation
import AVFoundation
@testable import NovaPlayerKit

final class PlayerTests {
    @Test func testTimeFormattingHandlesInvalidAndLargeValues() {
        for value in [Double.nan, .infinity, -.infinity, -1, Double.greatestFiniteMagnitude] {
            #expect(PlayerState.formatTime(value) == "0:00")
        }
        #expect(PlayerState.formatTime(3665) == "1:01:05")
        #expect(PlayerState.formatTime(59.9) == "0:59")
    }
    @Test func testProgressClamping() {
        let state = PlayerState()
        state.duration = 100
        for (time, expected) in [(25.0, 0.25), (-1, 0), (120, 1), (.nan, 0), (.infinity, 0)] {
            state.currentTime = time
            #expect(state.progress == expected)
        }
    }
    @Test func testSettingsPersistenceAndReset() {
        let name = UUID().uuidString
        let defaults = UserDefaults(suiteName: name)!
        defer { defaults.removePersistentDomain(forName: name) }
        let settings = AppSettings(defaults: defaults)
        #expect(settings.skipInterval == 5)
        settings.skipInterval = 15
        settings.hoverPreviewEnabled = false
        #expect(AppSettings(defaults: defaults).skipInterval == 15)
        #expect(!(AppSettings(defaults: defaults).hoverPreviewEnabled))
        settings.resetToDefaults()
        #expect(AppSettings(defaults: defaults).skipInterval == 5)
        #expect(settings.hoverPreviewEnabled)
    }
    @Test func testLanguageTagsPreserveRegionalAndUnlistedLanguages() {
        #expect(AudioVoiceoverEngine.bcp47Code(for: "it") == "it-IT")
        #expect(AudioVoiceoverEngine.bcp47Code(for: "en-GB") == "en-GB")
        #expect(AudioVoiceoverEngine.bcp47Code(for: "nl") == "nl")
    }
    @Test @MainActor func testRateVolumeAndCloseLifecycle() {
        let engine = makeEngine()
        engine.settings.speedGranularity = 0.1
        engine.setRate(0.25)
        #expect(engine.state.playbackRate >= 0.25)
        engine.setRate(10)
        #expect(engine.state.playbackRate == 4)
        engine.settings.speedGranularity = 0
        engine.setRate(1.05)
        #expect(abs(engine.state.playbackRate - 1.05) <= 0.001)
        engine.setRate(.nan)
        #expect(engine.state.playbackRate.isFinite)
        engine.setVolume(2)
        #expect(engine.player.volume == 1)
        engine.toggleMute()
        #expect(engine.player.volume == 0)
        engine.setVolume(0.5)
        #expect(!(engine.state.isMuted))
        engine.play()
        #expect(!(engine.state.isPlaying))
        engine.subtitles.loadExternalSubtitleFile(url: fixture("sample", "srt"))
        engine.subtitles.updateTime(1)
        engine.closeVideo()
        #expect(engine.player.currentItem == nil)
        #expect(engine.subtitles.activeSubtitleText == nil)
        #expect(engine.subtitles.availableSubtitleTracks.isEmpty)
        #expect(!(engine.state.isBuffering))
    }
}

func fixture(_ name: String, _ ext: String) -> URL {
    Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Fixtures")!
}

func makeEngine() -> PlaybackEngine {
    let name = "NovaPlayerTests-\(UUID())"
    let defaults = UserDefaults(suiteName: name)!
    let settings = AppSettings(defaults: defaults)
    // Volatile domain avoids changing the user's settings.
    defaults.removePersistentDomain(forName: name)
    let voice = AudioVoiceoverEngine()
    return PlaybackEngine(state: PlayerState(), settings: settings,
                          subtitles: SubtitleManager(voiceover: voice),
                          thumbnails: ThumbnailService(), voiceover: voice)
}
