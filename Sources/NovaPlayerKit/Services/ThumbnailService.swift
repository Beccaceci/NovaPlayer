import Foundation
import AVFoundation
import AppKit

public final class ThumbnailService {
    private var imageGenerator: AVAssetImageGenerator?
    private let cache = NSCache<NSNumber, NSImage>()
    private var currentTask: Task<Void, Never>?
    private var activeAssetURL: URL?
    
    public init() {
        cache.countLimit = 250 // Holds ~250 preview frames in memory
    }
    
    public func setAsset(url: URL) {
        guard url != activeAssetURL else { return }
        activeAssetURL = url
        cache.removeAllObjects()
        currentTask?.cancel()
        
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        // 16:9 thumbnail preview size
        generator.maximumSize = CGSize(width: 240, height: 135)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 0.5, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 0.5, preferredTimescale: 600)
        self.imageGenerator = generator
    }
    
    public func requestThumbnail(at seconds: Double, completion: @escaping (NSImage?) -> Void) {
        let roundedKey = NSNumber(value: Int(seconds.rounded()))
        
        // Check cache first for instantaneous response
        if let cachedImage = cache.object(forKey: roundedKey) {
            completion(cachedImage)
            return
        }
        
        guard let generator = imageGenerator else {
            completion(nil)
            return
        }
        
        // Cancel previous pending generation so we don't lag behind rapid mouse scrubbing
        currentTask?.cancel()
        
        currentTask = Task {
            // Small debounce to avoid queuing frames during rapid sweep
            do {
                try await Task.sleep(nanoseconds: 25_000_000) // 25ms
            } catch {
                return
            }
            
            if Task.isCancelled { return }
            
            let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
            do {
                let (cgImage, _) = try await generator.image(at: cmTime)
                if Task.isCancelled { return }
                
                let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
                self.cache.setObject(nsImage, forKey: roundedKey)
                
                await MainActor.run {
                    completion(nsImage)
                }
            } catch {
                // If cancelled or failed, ignore
                if !Task.isCancelled {
                    await MainActor.run {
                        completion(nil)
                    }
                }
            }
        }
    }
    
    public func cancel() {
        currentTask?.cancel()
    }
}
