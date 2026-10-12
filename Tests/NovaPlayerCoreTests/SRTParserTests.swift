import Testing
import Foundation
@testable import NovaPlayerCore

final class SRTParserTests {
    @Test func testTimestampFormats() {
        #expect(SRTParser.parseTimestamp("01:02:03,456") == 3723.456)
        #expect(SRTParser.parseTimestamp("02:03.456") == 123.456)
    }
    @Test func testInvalidTimestamps() {
        for value in ["", "1", "a:b:c", "00:60:00", "00:00:60", "-1:00:00", "00:nan:00", "inf:00:00", "00:00:-1", "1.5:00:00"] {
            #expect(SRTParser.parseTimestamp(value) == nil)
        }
    }
    @Test func testBOMWindowsLineEndingsAndMarkup() {
        let cues = SRTParser.parse(content: "\u{feff}1\r\n00:00:01,000 --> 00:00:02,000\r\n<b>Hello</b>\r\nWorld\r\n")
        #expect(cues == [SubtitleCue(id: 1, startTime: 1, endTime: 2, text: "Hello\nWorld")])
    }
    @Test func testWebVTTSettingsAndSorting() {
        let cues = SRTParser.parse(content: "WEBVTT\n\n00:03.000 --> 00:04.000 align:start\nLater\n \n00:01.000 --> 00:02.000\nEarlier")
        #expect(cues.map(\.text) == ["Earlier", "Later"])
    }
    @Test func testRejectsEmptyAndReversedCues() {
        #expect(SRTParser.parse(content: "1\n00:00:02,000 --> 00:00:01,000\nBad\n\n2\n00:00:01,000 --> 00:00:02,000\n<i></i>").isEmpty)
    }
}
