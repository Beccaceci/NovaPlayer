# Language and operating-system roadmap

## Implemented first milestone: Italian ↔ English

The agreed priority is offline translation where possible, with online fallback allowed. The player now has an explicit English/Italian source selector and an **Allow online fallback** switch. Set the source to the subtitle file's actual language and select the other language as the target.

On macOS 26+, with a build made using Xcode 26 / Swift 6.2 or newer, playback first tries Apple's installed language resources. Open the subtitles menu and choose **Prepare offline translation** to let the system download the required resources. Keep the menu open until preparation finishes. Preparation needs internet access if resources are missing. Afterward the Italian/English translation itself can run locally. On macOS 26.4+, builds made with Swift 6.3+ explicitly request the low-latency translation strategy.

If resources are missing or local translation fails, the app uses MyMemory when fallback is enabled. Turn fallback off to prevent subtitle text from going to that provider; unavailable translation then leaves the original subtitles visible. Older macOS versions and builds made with older SDKs use the online path. This is an implementation boundary of the current adapter, not a claim that offline translation is impossible on macOS 15.

Changing the source, target, or fallback policy cancels pending work and clears cached translations. Cancellation never triggers an online fallback. Identical source and target languages bypass both providers. The fallback switch is currently session-only, so check it again after restarting the app.

This milestone covers external SRT/VTT text translation. It does not generate missing transcripts, translate embedded captions, or create synchronized dubbed audio. The Apple download dialog and real-device translation quality still need interactive validation; unit tests verify routing with controlled providers rather than claiming to benchmark Apple's models.

## What “every selected language” can mean

A language selector cannot create content that is absent. Offer three clearly labeled choices: supplied subtitle/audio tracks, generated translated subtitles, and generated spoken subtitles. Enable a language only when the chosen provider supports that source/target pair and, for speech, an installed voice exists. Explain unsupported combinations instead of silently using English.

Start with supplied multilingual files: embedded audio/subtitle tracks plus `movie.en.srt`, `movie.it.vtt`, etc. This needs no AI and gives the best authored result. A second original audio track is not interchangeable with synthesized speech.

## Practical pipeline without a large general-purpose model

1. Prefer authored subtitles. If none exist, optionally transcribe once using a small multilingual speech model; benchmark accuracy and real-time factor on the target hardware. [whisper.cpp](https://github.com/ggml-org/whisper.cpp) supports local execution and quantization. Avoid English-only `.en` models for multilingual input. Transcription and translation are separate stages.
2. Translate the transcript before playback or prepare a bounded look-ahead queue. Use an explicit source language, sentence context, original cue IDs and timestamps. Cache by content hash, source/target language, provider and model version. Do not perform unbounded work in the playback timer.
3. On macOS, evaluate [Apple Translation](https://developer.apple.com/documentation/translation). Check [LanguageAvailability](https://developer.apple.com/documentation/translation/languageavailability) at runtime and gate by OS/API availability; retain a fallback for the current macOS 14 baseline. Availability and downloadable language resources vary.
4. Across platforms, evaluate [Argos Translate](https://github.com/argosopentech/argos-translate): local, specialized translation models installed by language pair. Pivoting through an intermediate language expands coverage with a quality tradeoff. It still uses machine learning, but does not require a large chat model. A small translation sidecar process is simpler to replace than embedding Python into the player.
5. For generated audio, synthesize cue speech ahead of playback into cached audio segments. Schedule against the media clock; cancel/reposition on seek, pause and language changes. Decide how to handle overflow: modest time stretching, shorter translation, or a visible warning. Keep music/effects where possible, but clean dialogue replacement generally needs separate stems or source separation. System speech alone does not provide studio dubbing.

The MyMemory fallback adapter remains online. The UI now discloses sending subtitle text to that service. Automated tests use a stub transport and never transmit fixture subtitles. Long cues exceeding the online provider limit fall back to original text when offline translation is unavailable; this is an interim adapter, not the final multilingual engine.

## Suggested first milestone

Next, validate offline English ↔ Italian translation with installed resources and strengthen supplied-track selection. Add progress, cancel, retry, download-size indication and an original/translated comparison. Evaluate dialogue, names, accents, fast speech and long movies before expanding the supported list. Generate voiceover only after subtitle quality and synchronization are acceptable.

Useful product decisions for our brainstorming:

- Must everything work offline after model downloads, or is a hosted translation API acceptable?
- Which source/target languages matter first, and what older hardware must work?
- Is intelligible spoken translation sufficient, or is preserving distinct speakers essential?
- Should Windows/Linux share the same UI or can the macOS app remain native?

## Cross-platform options

| Approach | Benefit | Cost / constraint |
|---|---|---|
| Keep native macOS app; add a Qt/libmpv desktop shell | Preserve existing macOS experience; broad desktop playback backend | Separate UI implementation; shared contracts/fixtures rather than all Swift UI code |
| Qt/libmpv on all desktop OSs | One desktop UI and playback stack | Rewrite the SwiftUI/AppKit presentation layer |
| Tauri or Electron with browser video | Familiar web UI and simpler iteration | Codec/track behavior depends on webview and OS; external subtitle/audio support needs careful implementation |
| Web UI with native libmpv backend | Web UI with native media capabilities | Extra rendering/IPC integration and packaging complexity |

[libmpv](https://mpv.io/manual/stable/#embedding-into-other-programs-libmpv) is designed for embedding. Prefer structured commands over shell command strings. Before choosing it, prototype hardware decode, native window embedding, subtitles and packaging on each OS; review the licenses of the actual distributed build and codecs.

Implemented now: `NovaPlayerCore` contains Foundation-only cue/track models and parsing; the package excludes macOS targets on other platforms and CI tests the core on Linux. This does **not** make the desktop app run on Linux or Windows. A Swift core can be reused by Swift consumers; Qt/Tauri require an explicit bridge or a shared data contract, so do not build that bridge until the shell choice is made.

Recommended next architecture experiment: a small Qt/libmpv player exercising load/play/pause/seek, two audio tracks, an external VTT file and track-switch events on macOS, Windows and Linux. Retain the native app until that experiment proves the backend and packaging. Do not promise cross-platform parity from a directory scaffold or a browser `<video>` demo.
