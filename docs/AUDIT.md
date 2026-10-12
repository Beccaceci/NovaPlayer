# Code audit and verification — 11 October 2026

Scope: Swift package, playback/subtitle/voiceover/thumbnail services, state and settings, views, keyboard handling, app entry point, packaging scripts and CI. This is a source audit and regression suite, not a guarantee of correctness for all media, hardware or operating systems.

## Findings addressed

| Severity | Finding | Change |
|---|---|---|
| High | An uncached subtitle starts another HTTP request every 1/30 second; errors retry indefinitely | One attempt per cue/language per selection, cancellable tasks, error fallback and injectable translator |
| High | A response for an old movie, track or language can overwrite current subtitles | Generation token plus active cue/language checks; reset cancels pending work |
| High | Query interpolation can corrupt subtitle text containing `&` or other delimiters; HTTP 200 does not imply translation success | URL query items, explicit source language, provider status validation, timeout and byte limit |
| High | Nonfinite or huge times can trap when converted to integers | Validate numeric inputs before formatting, seeking and thumbnail lookup |
| Medium | Rate rounding can exceed limits; zero granularity divides by zero | Validate settings and clamp the rounded rate |
| Medium | Closing leaves subtitle tracks and preview work behind; old item callbacks can update new media | Reset services, invalidate item observation and reject obsolete status callbacks |
| Medium | Duplicate display names produce duplicate track IDs | IDs use the index within the asset's selection group |
| Medium | `film2.srt` is discovered for `film.mp4`; adjacent cues overlap at their boundary | Filename boundary matching, sorted discovery, half-open cue intervals |
| Medium | Late thumbnail callbacks can populate another asset's cache; cancelled requests omit completion | Asset generation validation and completion for cancellation/failure |
| Medium | Voiceover is not stopped by pause/seek; restoring volume can undo mute | Stop speech on pause/seek, maintain voiceover base volume from playback controls |
| Medium | Unknown voice languages silently become US English | Preserve unlisted language tags and regional variants |
| Medium | Global services prevent isolated playback tests | Inject subtitle, thumbnail and voiceover services; root view follows engine dependencies |
| Medium | Custom nine-check executable silently skips missing media; no PR test gate | Swift Testing targets, tracked bundled fixtures, macOS/core CI, separate XCUITest project |

## Open findings and deliberate limits

- **Main-thread isolation:** observable classes are not yet consistently `@MainActor`. UI callers and new translation completions run on the main thread, but public APIs do not enforce that contract. Existing speech-delegate Sendable warnings remain with the installed preview SDK. Complete the actor migration with a deliberate Swift 6 concurrency pass.
- **Track loading:** synchronous `mediaSelectionGroup` calls are deprecated and can block the UI. Migrate to async loading with generation checks. Read the actual selected audio option rather than assuming the first option is selected.
- **Playback errors:** missing/corrupt media has no useful error UI. Add a published error state and recovery action; the current suite does not certify every codec or corrupt file.
- **Embedded subtitles:** AVPlayerLayer rendering and extracting timed text are different concerns. Current translation and spoken subtitles apply to external SRT/VTT only. Use AVPlayerItemLegibleOutput for supported embedded text; image subtitles need OCR or remain untranslated.
- **Translation quality/capacity:** source language now comes from an explicit English/Italian user choice. Metadata-based selection remains future work. MyMemory is an online provider with limits, not a promise of arbitrary-language availability. Failed cues retry only after selection changes; there is no batch preparation, durable cache or global queue limit yet.
- **Voiceover:** system speech is an accessibility-style reading, not a synchronized dub. It does not preserve speakers, background separation, exact timing or pitch relative to playback speed. The subtitle UI still references the shared speech service. Speech availability must be checked and shown to the user; “original” now uses the selected source language; metadata-based source selection remains future work.
- **Subtitle parsing:** basic text cues only; not full WebVTT regions/styles, ASS layout, HTML entity decoding, overlapping multi-speaker rendering or every legacy encoding. Lookup scans cues linearly; optimize only with realistic long-file measurements.
- **Keyboard/accessibility:** shortcuts can consume input intended for editable controls. UI accessibility coverage is started, not exhaustive; test keyboard focus, VoiceOver, fullscreen and multiple monitors.
- **Distribution:** current signing is ad hoc. Public macOS releases need a separate signing/notarization process. Release workflow previously published without tests; unit/integration checks now precede packaging. GUI tests remain a separate CI job.
- **Platforms:** only the Foundation-based core is portable. AppKit, SwiftUI, AVFoundation and NaturalLanguage remain in the macOS layer. Empty local `cross-platform` directories contain no tracked implementation.

## Test layers

See [TESTING.md](TESTING.md) for commands, coverage boundaries and environment requirements. UI tests are separate from service integration tests: calling PlaybackEngine alone is not labeled end-to-end testing.
