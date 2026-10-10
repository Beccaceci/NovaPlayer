import Foundation

public struct SubtitleCue: Identifiable, Equatable {
    public let id: Int
    public let startTime: Double
    public let endTime: Double
    public var text: String
    
    public init(id: Int, startTime: Double, endTime: Double, text: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }
}

public struct MediaTrackOption: Identifiable, Hashable {
    public let id: String
    public let displayName: String
    public let languageCode: String?
    public let isEmbedded: Bool
    
    public init(id: String, displayName: String, languageCode: String? = nil, isEmbedded: Bool = true) {
        self.id = id
        self.displayName = displayName
        self.languageCode = languageCode
        self.isEmbedded = isEmbedded
    }
}
