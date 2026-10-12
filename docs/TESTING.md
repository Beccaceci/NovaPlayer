# Running and extending the tests

Requires Swift 6 or newer. The app still targets macOS 14 or newer. Tests use Swift Testing in Swift 5 language mode; the portable target depends only on Foundation.

```sh
scripts/test.sh
scripts/test.sh --enable-code-coverage
swift build -c release --product NovaPlayer
```

The script normally runs `swift test --disable-xctest`. On the installed preview Command Line Tools, it supplies the bundled Testing framework/macro paths and uses the native build system to work around framework discovery. Full Xcode and Linux do not use that workaround.

## Coverage and fixtures

- `NovaPlayerCoreTests`: timestamp validation, malformed cues, sorting, line endings, markup and basic WebVTT.
- `PlayerTests`: settings persistence/reset, time/progress, language tags, speed/volume and close/reset behavior.
- `SubtitleTests`: half-open boundaries, discovery, off/reset, successful cache reuse, request deduplication, stale language responses and failure suppression.
- `TranslationIntegrationTests`: real URLSession with a stub URLProtocol; checks query encoding, source/target pair, successful decoding, HTTP errors, provider errors and malformed JSON. No network requests.
- `MediaIntegrationTests`: actual bundled MP4 decode, playback time advancement, pause/seek, subtitles, playback speed, thumbnails and close/reload.
- `OfflineTranslationTests`: both language directions, local preference, online fallback, offline-only enforcement, cancellation, same-language bypass and source/policy resets. Providers are controlled stubs; these tests do not establish real Apple model availability or quality.
- `UITests`: a separate XCTest UI runner launches the app and drives actual buttons/keyboard and the track menu. These tests do not call the playback engine directly.

The small synthetic MP4 and SRT are tracked under `Tests/NovaPlayerTests/Fixtures`. Tests never depend on the ignored root `sample.mp4`, and missing fixtures fail rather than silently skip. Media tests have bounded polling of observable conditions. Translation tests inject a controlled provider. User preferences use separate suite names.

## End-to-end UI tests

Install full Xcode and XcodeGen, select the full Xcode developer directory, and use an interactive macOS session:

```sh
scripts/test_ui.sh
```

The script generates an ignored Xcode project from `UITests/project.yml`, builds the same app entry point/library, and writes `.xcresult` results under `build`. The separate test app uses its own bundle identifier. macOS may require UI automation permission for the test runner. The script exits with an explicit error if Xcode is absent; it never reports a skip as success.

CI runs macOS unit/integration tests, release compilation, UI tests, and Foundation-core tests on Linux. Tagged release packaging now also requires unit/integration tests. Configuring required branch checks remains a repository setting.

## Local verification — 11 October 2026

The initial 20 unit/integration tests passed with coverage enabled. After adding offline-first routing, all 26 unit/integration tests passed. The release app build also passed. Selected production-source line coverage: parser 98.6%, settings 100%, state 88.4%, translation adapter 95%, subtitles 75.4%, thumbnails 91.7%, playback 79.6%, voiceover 49.4%. SwiftUI views and keyboard routing are not exercised by this local run; do not present these selected numbers as whole-app coverage.

UI runner was invoked and stopped because full Xcode is absent. Its tests are provided but remain unverified locally. Windows desktop behavior is unverified. Linux CI is configured; local execution was unavailable because Docker is not running.

Remaining scenarios: corrupt/unsupported media, multiple embedded tracks with matching display names, speech delegate timing and audible output, translation races across full asset replacement, large subtitle performance, fullscreen/multi-monitor controls, accessibility focus, and installation/signing. Expand fixtures and tests alongside those features. No finite suite guarantees all best practices or all playback formats.
