import Foundation
import AVFoundation
import AppKit
import Combine

public final class PlaybackEngine: ObservableObject {
    public static let shared = PlaybackEngine(state: PlayerState.shared)
    
    public let player = AVPlayer()
    public let state: PlayerState
    public let settings: AppSettings
    
    private var timeObserverToken: Any?
    private var itemStatusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var bufferObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()
    
    public init(state: PlayerState, settings: AppSettings = .shared) {
        self.state = state
        self.settings = settings
        setupPlayer()
        setupObservers()
    }
    
    deinit {
        removeObservers()
    }
    
    private func setupPlayer() {
        let interval = CMTime(value: 1, timescale: 30)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let seconds = CMTimeGetSeconds(time)
            if !seconds.isNaN && !seconds.isInfinite {
                self.state.currentTime = seconds
                SubtitleManager.shared.updateTime(seconds)
            }
        }
        
        timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.state.isPlaying = (player.timeControlStatus == .playing)
                self.state.isBuffering = (player.timeControlStatus == .waitingToPlayAtSpecifiedRate)
            }
        }
    }
    
    private func setupObservers() {
        // Observe settings changes if needed
    }
    
    private func removeObservers() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
        itemStatusObserver?.invalidate()
        timeControlObserver?.invalidate()
        bufferObserver?.invalidate()
    }
    
    // MARK: - Media Loading
    
    public func loadVideo(url: URL) {
        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        
        // Preserve natural pitch across all speeds
        item.audioTimePitchAlgorithm = .timeDomain
        
        itemStatusObserver?.invalidate()
        bufferObserver?.invalidate()
        
        itemStatusObserver = item.observe(\.status, options: [.new]) { [weak self] item, _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if item.status == .readyToPlay {
                    let dur = CMTimeGetSeconds(item.duration)
                    if !dur.isNaN && !dur.isInfinite {
                        self.state.duration = dur
                    }
                }
            }
        }
        
        self.state.currentURL = url
        self.state.videoTitle = url.deletingPathExtension().lastPathComponent
        self.state.currentTime = 0
        self.state.duration = 0
        
        player.replaceCurrentItem(with: item)
        SubtitleManager.shared.attach(player: player)
        SubtitleManager.shared.didLoadAsset(asset, videoURL: url)
        play()
    }
    
    public func closeVideo() {
        pause()
        player.replaceCurrentItem(with: nil)
        AudioVoiceoverEngine.shared.stop()
        state.currentURL = nil
        state.videoTitle = "No Video Loaded"
        state.currentTime = 0
        state.duration = 0
        state.isPlaying = false
    }
    
    // MARK: - Playback Control
    
    public func play() {
        player.play()
        applyCurrentRate()
        state.isPlaying = true
    }
    
    public func pause() {
        player.pause()
        state.isPlaying = false
    }
    
    public func togglePlayPause() {
        if state.isPlaying {
            pause()
            state.showHUD(text: "Paused", icon: "pause.fill")
        } else {
            play()
            state.showHUD(text: "Play", icon: "play.fill")
        }
    }
    
    // MARK: - Playback Rate with Granularity
    
    public func setRate(_ rate: Float) {
        let clamped = max(0.25, min(rate, 4.0))
        let granularity = settings.speedGranularity
        // Round to nearest multiple of granularity to avoid 1.05000001 inaccuracies
        let rounded = (clamped / granularity).rounded() * granularity
        state.playbackRate = rounded
        applyCurrentRate()
        state.showHUD(text: String(format: "Speed: %.2f×", rounded), icon: "speedometer")
    }
    
    public func stepRate(forward: Bool) {
        let delta = forward ? settings.speedGranularity : -settings.speedGranularity
        setRate(state.playbackRate + delta)
    }
    
    private func applyCurrentRate() {
        player.currentItem?.audioTimePitchAlgorithm = .timeDomain
        if state.isPlaying {
            player.rate = state.playbackRate
        }
    }
    
    // MARK: - Seeking
    
    public func skip(by seconds: Double) {
        let target = max(0, min(state.currentTime + seconds, state.duration))
        seek(to: target, precise: true)
        
        let roundedSeconds = Int(abs(seconds))
        if seconds > 0 {
            state.showHUD(text: "+\(roundedSeconds)s", icon: "goforward")
        } else {
            state.showHUD(text: "-\(roundedSeconds)s", icon: "gobackward")
        }
    }
    
    public func skipForward() {
        skip(by: settings.skipInterval)
    }
    
    public func skipBackward() {
        skip(by: -settings.skipInterval)
    }
    
    public func jumpToPercentage(_ fraction: Double) {
        guard state.duration > 0 else { return }
        let clamped = max(0.0, min(fraction, 1.0))
        let target = clamped * state.duration
        seek(to: target, precise: true)
        state.showHUD(text: "\(Int(clamped * 100))%", icon: "percent")
    }
    
    public func seek(to seconds: Double, precise: Bool = true) {
        guard state.duration > 0 else { return }
        let clampedSeconds = max(0, min(seconds, state.duration))
        let cmTime = CMTime(seconds: clampedSeconds, preferredTimescale: 600)
        
        let tolerance = precise ? CMTime.zero : CMTime(seconds: 0.5, preferredTimescale: 600)
        player.seek(to: cmTime, toleranceBefore: tolerance, toleranceAfter: tolerance) { [weak self] _ in
            if self?.state.isPlaying == true {
                self?.applyCurrentRate()
            }
        }
    }
    
    public func seekToFraction(_ fraction: Double, precise: Bool = false) {
        guard state.duration > 0 else { return }
        let target = fraction * state.duration
        seek(to: target, precise: precise)
    }
    
    // MARK: - Volume & Mute
    
    public func setVolume(_ volume: Float) {
        let clamped = max(0.0, min(volume, 1.0))
        state.volume = clamped
        if state.isMuted && clamped > 0 {
            state.isMuted = false
        }
        player.volume = state.isMuted ? 0 : clamped
        state.showHUD(text: "\(Int(clamped * 100))%", icon: clamped > 0.5 ? "speaker.wave.3.fill" : (clamped > 0 ? "speaker.wave.1.fill" : "speaker.slash.fill"))
    }
    
    public func adjustVolume(by delta: Float) {
        setVolume(state.volume + delta)
    }
    
    public func toggleMute() {
        state.isMuted.toggle()
        player.volume = state.isMuted ? 0 : state.volume
        if state.isMuted {
            state.showHUD(text: "Muted", icon: "speaker.slash.fill")
        } else {
            state.showHUD(text: "\(Int(state.volume * 100))%", icon: "speaker.wave.2.fill")
        }
    }
}
