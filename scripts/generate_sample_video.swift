import Foundation
import AVFoundation
import CoreGraphics
import AppKit

let outputURL = URL(fileURLWithPath: "sample.mp4")
try? FileManager.default.removeItem(at: outputURL)

let width = 1280
let height = 720
let fps: Int32 = 30
let durationSeconds = 30
let totalFrames = Int(fps) * durationSeconds

guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
    print("Failed to create writer")
    exit(1)
}

let videoSettings: [String: Any] = [
    AVVideoCodecKey: AVVideoCodecType.h264,
    AVVideoWidthKey: width,
    AVVideoHeightKey: height
]

let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
let adaptor = AVAssetWriterInputPixelBufferAdaptor(
    assetWriterInput: writerInput,
    sourcePixelBufferAttributes: [
        kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32ARGB),
        kCVPixelBufferWidthKey as String: width,
        kCVPixelBufferHeightKey as String: height
    ]
)

writer.add(writerInput)
writer.startWriting()
writer.startSession(atSourceTime: .zero)

var pixelBuffer: CVPixelBuffer?
CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &pixelBuffer)

let colorSpace = CGColorSpaceCreateDeviceRGB()

for frameIndex in 0..<totalFrames {
    while !writerInput.isReadyForMoreMediaData {
        usleep(1000)
    }
    
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, adaptor.pixelBufferPool!, &buffer)
    guard let pb = buffer else { continue }
    
    CVPixelBufferLockBaseAddress(pb, [])
    let data = CVPixelBufferGetBaseAddress(pb)
    let context = CGContext(
        data: data,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: CVPixelBufferGetBytesPerRow(pb),
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue
    )!
    
    let progress = Double(frameIndex) / Double(totalFrames)
    let currentSeconds = Double(frameIndex) / Double(fps)
    
    // Draw dynamic background
    let r = CGFloat(0.1 + 0.6 * sin(progress * .pi * 2))
    let g = CGFloat(0.2 + 0.5 * cos(progress * .pi * 2))
    let b = CGFloat(0.6 + 0.3 * sin(progress * .pi * 4))
    context.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1.0))
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Draw moving indicator
    let boxX = CGFloat(progress) * CGFloat(width - 100)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.9))
    context.fill(CGRect(x: boxX, y: CGFloat(height / 2 - 50), width: 100, height: 100))
    
    CVPixelBufferUnlockBaseAddress(pb, [])
    
    let frameTime = CMTime(value: Int64(frameIndex), timescale: fps)
    adaptor.append(pb, withPresentationTime: frameTime)
}

writerInput.markAsFinished()
let group = DispatchGroup()
group.enter()
writer.finishWriting {
    group.leave()
}
group.wait()

print("Generated \(outputURL.path) (\(durationSeconds)s, \(width)x\(height) @ \(fps)fps)")
