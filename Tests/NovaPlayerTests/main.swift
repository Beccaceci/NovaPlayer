import Foundation
import AppKit
import NovaPlayerKit

func assertEqual<T: Equatable>(_ actual: T, _ expected: T, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if actual != expected {
        print("❌ FAILED: \(actual) != \(expected). \(message) (\(file):\(line))")
        exit(1)
    }
}

func assertEqualDouble(_ actual: Double, _ expected: Double, accuracy: Double = 0.001, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if abs(actual - expected) > accuracy {
        print("❌ FAILED: \(actual) not within \(accuracy) of \(expected). \(message) (\(file):\(line))")
        exit(1)
    }
}

func assertEqualFloat(_ actual: Float, _ expected: Float, accuracy: Float = 0.001, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if abs(actual - expected) > accuracy {
        print("❌ FAILED: \(actual) not within \(accuracy) of \(expected). \(message) (\(file):\(line))")
        exit(1)
    }
}

func assertTrue(_ condition: Bool, _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    if !condition {
        print("❌ FAILED: condition was false. \(message) (\(file):\(line))")
        exit(1)
    }
}

print("🧪 Starting NovaPlayer Test Suite...")

// Test 1: AppSettings Defaults
print("  ▶ Running testAppSettingsDefaults...")
do {
    let testDefaults = UserDefaults(suiteName: "NovaPlayerTests-\(UUID().uuidString)")!
    let settings = AppSettings(defaults: testDefaults)
    assertEqualDouble(settings.skipInterval, 5.0, "Default skip interval should be 5 seconds")
    assertEqualFloat(settings.speedGranularity, 0.05, "Default speed granularity should be 0.05")
    assertTrue(settings.hoverPreviewEnabled, "Hover preview should be enabled by default")
    assertEqualDouble(settings.autoHideDelay, 2.5, "Default auto hide delay should be 2.5 seconds")
    print("    ✅ Passed")
}

// Test 2: Time Formatting
print("  ▶ Running testTimeFormatting...")
do {
    assertEqual(PlayerState.formatTime(0), "0:00")
    assertEqual(PlayerState.formatTime(5), "0:05")
    assertEqual(PlayerState.formatTime(59), "0:59")
    assertEqual(PlayerState.formatTime(60), "1:00")
    assertEqual(PlayerState.formatTime(125), "2:05")
    assertEqual(PlayerState.formatTime(3600), "1:00:00")
    assertEqual(PlayerState.formatTime(3665), "1:01:05")
    assertEqual(PlayerState.formatTime(-10), "0:00")
    assertEqual(PlayerState.formatTime(.nan), "0:00")
    print("    ✅ Passed")
}

// Test 3: Progress Calculation
print("  ▶ Running testProgressCalculation...")
do {
    let state = PlayerState()
    state.duration = 100.0
    state.currentTime = 25.0
    assertEqualDouble(state.progress, 0.25, accuracy: 0.001)
    
    state.currentTime = 120.0
    assertEqualDouble(state.progress, 1.0, accuracy: 0.001) // Clamped to 1.0
    
    state.currentTime = -10.0
    assertEqualDouble(state.progress, 0.0, accuracy: 0.001) // Clamped to 0.0
    
    state.duration = 0.0
    assertEqualDouble(state.progress, 0.0, accuracy: 0.001) // 0 duration handled
    print("    ✅ Passed")
}

// Test 4: Speed Granularity (0.05x stepping)
print("  ▶ Running testSpeedGranularityStepping...")
do {
    let state = PlayerState()
    let testDefaults = UserDefaults(suiteName: "NovaPlayerTests-\(UUID().uuidString)")!
    let settings = AppSettings(defaults: testDefaults)
    settings.speedGranularity = 0.05
    let engine = PlaybackEngine(state: state, settings: settings)
    
    engine.setRate(1.0)
    assertEqualFloat(state.playbackRate, 1.00)
    assertEqual(state.formattedPlaybackRate(), "1.00×")
    
    // Step forward by 0.05
    engine.stepRate(forward: true)
    assertEqualFloat(state.playbackRate, 1.05)
    assertEqual(state.formattedPlaybackRate(), "1.05×")
    
    // Step forward again to 1.10
    engine.stepRate(forward: true)
    assertEqualFloat(state.playbackRate, 1.10)
    assertEqual(state.formattedPlaybackRate(), "1.10×")
    
    // Step backward to 1.05
    engine.stepRate(forward: false)
    assertEqualFloat(state.playbackRate, 1.05)
    assertEqual(state.formattedPlaybackRate(), "1.05×")
    
    // Custom granularity 0.10
    settings.speedGranularity = 0.10
    engine.setRate(1.0)
    engine.stepRate(forward: true)
    assertEqualFloat(state.playbackRate, 1.10)
    assertEqual(state.formattedPlaybackRate(), "1.10×")
    
    // Clamping min/max
    engine.setRate(0.10)
    assertTrue(state.playbackRate >= 0.25, "Rate should be clamped to minimum 0.25")
    
    engine.setRate(5.00)
    assertTrue(state.playbackRate <= 4.00, "Rate should be clamped to maximum 4.00")
    print("    ✅ Passed")
}

// Test 5: HUD Notices
print("  ▶ Running testHUDNoticeGeneration...")
do {
    let state = PlayerState()
    state.showHUD(text: "+5s", icon: "goforward", duration: 0.5)
    assertTrue(state.hudNotice != nil, "HUD notice should be set")
    assertEqual(state.hudNotice?.text, "+5s")
    assertEqual(state.hudNotice?.iconName, "goforward")
    print("    ✅ Passed")
}

// Test 6: Thumbnail Extraction
print("  ▶ Running testThumbnailExtraction...")
do {
    var completed = false
    var extractedImage: NSImage?
    let thumbService = ThumbnailService()
    let sampleURL = URL(fileURLWithPath: "sample.mp4")
    if FileManager.default.fileExists(atPath: sampleURL.path) {
        thumbService.setAsset(url: sampleURL)
        thumbService.requestThumbnail(at: 5.0) { image in
            extractedImage = image
            completed = true
        }
        let deadline = Date().addingTimeInterval(5.0)
        while !completed && Date() < deadline {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        }
        assertTrue(completed, "Thumbnail extraction timed out")
        assertTrue(extractedImage != nil, "Thumbnail should be extracted from sample.mp4")
        if let img = extractedImage {
            assertTrue(img.size.width > 0 && img.size.height > 0, "Thumbnail should have valid dimensions")
        }
        print("    ✅ Passed")
    } else {
        print("    ⚠️ sample.mp4 not found, skipping")
    }
}

// Test 7: SRT Parser & Subtitle Matching
print("  ▶ Running testSRTParser...")
do {
    let srtSample = """
    1
    00:00:01,000 --> 00:00:04,500
    Hello, welcome to NovaPlayer!
    
    2
    00:00:05,200 --> 00:00:08,000
    Enjoy fine-grained speed and subtitles.
    """
    let cues = SRTParser.parse(content: srtSample)
    assertEqual(cues.count, 2, "Should parse 2 cues")
    assertEqualDouble(cues[0].startTime, 1.0)
    assertEqualDouble(cues[0].endTime, 4.5)
    assertEqual(cues[0].text, "Hello, welcome to NovaPlayer!")
    assertEqualDouble(cues[1].startTime, 5.2)
    assertEqualDouble(cues[1].endTime, 8.0)
    print("    ✅ Passed")
}

// Test 8: Audio Voiceover Language Mapping
print("  ▶ Running testAudioVoiceoverEngine...")
do {
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "it"), "it-IT")
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "es"), "es-ES")
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "fr"), "fr-FR")
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "de"), "de-DE")
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "en"), "en-US")
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "ja"), "ja-JP")
    assertEqual(AudioVoiceoverEngine.bcp47Code(for: "zh"), "zh-CN")
    print("    ✅ Passed")
}

// Test 9: Close Video & State Transition
print("  ▶ Running testCloseVideo...")
do {
    let state = PlayerState()
    let settings = AppSettings()
    let engine = PlaybackEngine(state: state, settings: settings)
    
    state.currentURL = URL(fileURLWithPath: "sample.mp4")
    state.videoTitle = "sample"
    state.currentTime = 14.5
    state.duration = 30.0
    state.isPlaying = true
    
    engine.closeVideo()
    
    assertTrue(state.currentURL == nil, "currentURL should be nil after closing")
    assertEqual(state.videoTitle, "No Video Loaded")
    assertEqualDouble(state.currentTime, 0.0)
    assertEqualDouble(state.duration, 0.0)
    assertTrue(!state.isPlaying, "Player should be paused after closing")
    print("    ✅ Passed")
}

print("🎉 All 9 test suites passed successfully!")

