import Foundation
import AVFoundation
import AppKit

public final class ThumbnailService {
    public static let shared = ThumbnailService()
    
    private var imageGenerator: AVAssetImageGenerator?
    private let cache = NSCache<NSNumber, NSImage>()
    private var activeAssetURL: URL?
    private var generation = UUID()
    
    public init() {
        cache.countLimit = 300 // Holds ~300 preview frames in memory
    }
    
    public func setAsset(url: URL) {
        guard url != activeAssetURL else { return }
        reset()
        activeAssetURL = url
        cache.removeAllObjects()
        
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // 16:9 thumbnail preview size (Retina @2x friendly)
        generator.maximumSize = CGSize(width: 384, height: 216)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 1.0, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1.0, preferredTimescale: 600)
        self.imageGenerator = generator
    }
    
    public func requestThumbnail(at seconds: Double, completion: @escaping (NSImage?) -> Void) {
        guard seconds.isFinite, seconds >= 0, seconds < Double(Int.max) else { completion(nil); return }
        let roundedKey = NSNumber(value: Int(seconds.rounded()))
        
        // 1. Instant Cache Hit
        if let cachedImage = cache.object(forKey: roundedKey) {
            completion(cachedImage)
            return
        }
        
        guard let generator = imageGenerator else {
            completion(nil)
            return
        }
        
        let requestGeneration = generation
        let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
        
        // 2. Asynchronous generation without blocking the main thread
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { [weak self] _, cgImage, _, result, _ in
            DispatchQueue.main.async {
                guard let self, self.generation == requestGeneration else { completion(nil); return }
                if result == .succeeded, let cgImage {
                    let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                    self.cache.setObject(image, forKey: roundedKey)
                    completion(image)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
    public func reset() {
        generation = UUID()
        imageGenerator?.cancelAllCGImageGeneration()
        imageGenerator = nil
        activeAssetURL = nil
        cache.removeAllObjects()
    }

    public func cancel() {
        imageGenerator?.cancelAllCGImageGeneration()
    }
}
