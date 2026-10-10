import Foundation
import Combine

public final class AppSettings: ObservableObject {
    public static let shared = AppSettings()
    
    private let defaults: UserDefaults
    
    private enum Keys {
        static let skipInterval = "NovaPlayer.skipInterval"
        static let speedGranularity = "NovaPlayer.speedGranularity"
        static let hoverPreviewEnabled = "NovaPlayer.hoverPreviewEnabled"
        static let autoHideDelay = "NovaPlayer.autoHideDelay"
    }
    
    @Published public var skipInterval: Double {
        didSet {
            defaults.set(skipInterval, forKey: Keys.skipInterval)
        }
    }
    
    @Published public var speedGranularity: Float {
        didSet {
            defaults.set(speedGranularity, forKey: Keys.speedGranularity)
        }
    }
    
    @Published public var hoverPreviewEnabled: Bool {
        didSet {
            defaults.set(hoverPreviewEnabled, forKey: Keys.hoverPreviewEnabled)
        }
    }
    
    @Published public var autoHideDelay: Double {
        didSet {
            defaults.set(autoHideDelay, forKey: Keys.autoHideDelay)
        }
    }
    
    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        
        let storedSkip = defaults.double(forKey: Keys.skipInterval)
        self.skipInterval = storedSkip > 0 ? storedSkip : 5.0
        
        let storedGranularity = defaults.float(forKey: Keys.speedGranularity)
        self.speedGranularity = storedGranularity > 0 ? storedGranularity : 0.05
        
        if defaults.object(forKey: Keys.hoverPreviewEnabled) != nil {
            self.hoverPreviewEnabled = defaults.bool(forKey: Keys.hoverPreviewEnabled)
        } else {
            self.hoverPreviewEnabled = true
        }
        
        let storedAutoHide = defaults.double(forKey: Keys.autoHideDelay)
        self.autoHideDelay = storedAutoHide > 0 ? storedAutoHide : 2.5
    }
    
    public func resetToDefaults() {
        self.skipInterval = 5.0
        self.speedGranularity = 0.05
        self.hoverPreviewEnabled = true
        self.autoHideDelay = 2.5
    }
    
    public static let availableSkipIntervals: [Double] = [3.0, 5.0, 10.0, 15.0, 30.0]
    public static let availableSpeedGranularities: [Float] = [0.01, 0.02, 0.05, 0.10]
}
