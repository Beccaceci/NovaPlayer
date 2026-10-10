import Foundation
import AVFoundation
import AppKit

public final class ThumbnailService {
    public static let shared = ThumbnailService()
    
    private var imageGenerator: AVAssetImageGenerator?
    private let cache = NSCache<NSNumber, NSImage>()
    private var activeAssetURL: URL?
    private var pendingRequestTime: Double?
    
    public init() {
        cache.countLimit = 300 // Holds ~300 preview frames in memory
    }
    
    public func setAsset(url: URL) {
        guard url != activeAssetURL else { return }
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
        
        pendingRequestTime = seconds
        let targetTime = seconds
        let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
        
        // 2. Asynchronous generation without blocking the main thread
        generator.generateCGImagesAsynchronously(forTimes: [NSValue(time: cmTime)]) { [weak self] _, cgImage, _, result, _ in
            guard let self = self else { return }
            
            if result == .succeeded, let cgImage = cgImage {
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                self.cache.setObject(nsImage, forKey: roundedKey)
                
                DispatchQueue.main.async {
                    completion(nsImage)
                }
            } else if result == .failed {
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    public func cancel() {
        imageGenerator?.cancelAllCGImageGeneration()
    }
}
