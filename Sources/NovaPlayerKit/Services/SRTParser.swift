import Foundation

public struct SRTParser {
    public static func parse(content: String) -> [SubtitleCue] {
        var cues: [SubtitleCue] = []
        let normalized = content.replacingOccurrences(of: "\r\n", with: "\n").replacingOccurrences(of: "\r", with: "\n")
        let blocks = normalized.components(separatedBy: "\n\n")
        
        var nextId = 1
        for block in blocks {
            let lines = block.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
            guard !lines.isEmpty else { continue }
            
            // Look for line containing '-->'
            var timeLineIndex: Int?
            for (idx, line) in lines.enumerated() {
                if line.contains("-->") {
                    timeLineIndex = idx
                    break
                }
            }
            
            guard let timeIdx = timeLineIndex else { continue }
            let timeLine = lines[timeIdx]
            let parts = timeLine.components(separatedBy: "-->")
            guard parts.count == 2 else { continue }
            
            let startString = parts[0].trimmingCharacters(in: .whitespaces)
            // Strip any VTT cue settings from end time (e.g. "00:01:00.000 align:start")
            let endString = parts[1].trimmingCharacters(in: .whitespaces).components(separatedBy: " ").first ?? ""
            
            guard let start = parseTimestamp(startString),
                  let end = parseTimestamp(endString),
                  end > start else {
                continue
            }
            
            let textLines = lines.dropFirst(timeIdx + 1)
            let rawText = textLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedText = cleanHTML(rawText)
            
            guard !cleanedText.isEmpty else { continue }
            
            cues.append(SubtitleCue(id: nextId, startTime: start, endTime: end, text: cleanedText))
            nextId += 1
        }
        
        return cues.sorted(by: { $0.startTime < $1.startTime })
    }
    
    public static func parseTimestamp(_ string: String) -> Double? {
        let cleaned = string.replacingOccurrences(of: ",", with: ".")
        let parts = cleaned.components(separatedBy: ":")
        
        if parts.count == 3 {
            guard let h = Double(parts[0]),
                  let m = Double(parts[1]),
                  let s = Double(parts[2]) else { return nil }
            return h * 3600 + m * 60 + s
        } else if parts.count == 2 {
            guard let m = Double(parts[0]),
                  let s = Double(parts[1]) else { return nil }
            return m * 60 + s
        }
        return nil
    }
    
    private static func cleanHTML(_ text: String) -> String {
        return text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
    }
}
