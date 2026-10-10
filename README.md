# NovaPlayer 🚀

A modern, high-performance macOS video player with **YouTube-style ergonomics**, built natively with **Swift 6, SwiftUI, and AVFoundation**. Designed as a seamless, feature-packed alternative to QuickTime Player.

---

## ✨ Features

* **⚡ Granular Playback Speed:** Fine-tune playback speed with a step of **`0.05×`** (e.g. `1.05×`, `1.10×`, `1.15×`, `1.20×`), with automatic pitch preservation so voices remain natural.
* **⏩ 5-Second Seeking:** Instantly skip forward or backward by 5 seconds with hotkeys or on-screen controls, accompanied by transient YouTube-style HUD notices (`+5s` / `-5s`).
* **🎞️ Timeline Hover Frame Previews:** Hover your cursor anywhere along the scrubber bar to see a floating preview card with the exact corresponding video frame and timestamp.
* **🎛️ Fully Customizable:** Configure skip intervals (`3s`, `5s`, `10s`, `15s`, `30s`) and speed steps (`0.01×`, `0.02×`, `0.05×`, `0.10×`) in the built-in Preferences panel.
* **🎬 Floating Borderless Cinema Window:** Minimalist floating window where controls smoothly fade out during playback and reappear on mouse movement. You can drag the window from anywhere on the canvas.
* **🎯 Native Hardware Acceleration:** Uses `AVPlayer` with Metal-accelerated zero-copy video decoding for smooth 4K/60fps playback and minimal battery drain.
* **📁 Drag & Drop Support:** Drop any `.mp4`, `.mov`, or `.m4v` video directly into the player window.

---

## ⌨️ Keyboard Shortcuts (YouTube Muscle Memory)

| Shortcut | Action |
| :--- | :--- |
| `Space` or `K` | Toggle Play / Pause |
| `←` or `J` | Skip Backward by configured interval (default 5s) |
| `→` or `L` | Skip Forward by configured interval (default 5s) |
| `[` | Decrease Speed by configured step (default `0.05×`) |
| `]` | Increase Speed by configured step (default `0.05×`) |
| `↑` / `↓` | Increase / Decrease Volume by 5% |
| `M` | Toggle Mute |
| `F` | Toggle Fullscreen (or double-click video canvas) |
| `0` – `9` | Jump to 0% – 90% of total video duration |
| `Cmd + O` | Open Video File Dialog |

---

## 🏗️ Project Structure

```
nova-player/
├── Package.swift                    # Swift 6 Package Manifest
├── Sources/
│   ├── NovaPlayerKit/               # Core Application Framework
│   │   ├── Model/
│   │   │   ├── PlayerState.swift    # Observable state (time, rate, hover, volume)
│   │   │   └── AppSettings.swift    # Persisted preferences (skip interval, speed step)
│   │   ├── Services/
│   │   │   ├── PlaybackEngine.swift # AVPlayer lifecycle, time observing, pitch correction
│   │   │   └── ThumbnailService.swift # AVAssetImageGenerator + LRU frame caching
│   │   ├── Views/
│   │   │   ├── NovaPlayerRootView.swift # Root container & open file handler
│   │   │   ├── VideoSurfaceView.swift   # AppKit NSView wrapping AVPlayerLayer & drag/drop
│   │   │   ├── ControlsOverlayView.swift# Cinema overlay with top/bottom bars & HUD
│   │   │   ├── TimelineBarView.swift    # Scrubber with continuous hover tracking
│   │   │   ├── HoverThumbnailCard.swift # Floating frame preview tooltip
│   │   │   ├── SpeedControlPopover.swift# Granular speed stepper & presets
│   │   │   ├── SettingsView.swift       # Preferences popover
│   │   │   └── HUDIndicatorView.swift   # Transient center notifications
│   │   └── Controllers/
│   │       └── KeyCommandHandler.swift  # YouTube hotkey interceptor
│   └── NovaPlayer/
│       └── main.swift               # Application entrypoint & borderless window
├── Resources/
│   └── Info.plist                   # Bundle metadata and file associations
├── Tests/
│   └── NovaPlayerTests/             # Unit tests for speed math, formatting, state
└── scripts/
    └── build_app.sh                 # Builds and packages NovaPlayer.app
```

---

## 🚀 Building & Running

### Run directly with Swift:
```bash
cd nova-player
swift run NovaPlayer [optional_path_to_video.mp4]
```

### Build the macOS `.app` bundle:
```bash
cd nova-player
./scripts/build_app.sh
open build/NovaPlayer.app
```
