import Testing
import Foundation
@testable import NovaPlayerKit

private final class StubURLProtocol: URLProtocol {
    static var handler: ((URLRequest) throws -> (Int, Data))?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        do {
            let (status, data) = try Self.handler!(request)
            client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: status,
                                      httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch { client?.urlProtocol(self, didFailWithError: error) }
    }
    override func stopLoading() {}
}

@Suite(.serialized)
struct TranslationIntegrationTests {
    private func session() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }
    @Test func encodesQueryAndDecodesResponse() async throws {
        let text = "This is an English sentence about cats & dogs + their owners?"
        StubURLProtocol.handler = { request in
            let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
            #expect(items.first { $0.name == "q" }?.value == text)
            #expect(items.first { $0.name == "langpair" }?.value == "en|it")
            return (200, Data(#"{"responseStatus":200,"responseData":{"translatedText":"Tradotto"}}"#.utf8))
        }
        let session = session()
        defer { session.invalidateAndCancel(); StubURLProtocol.handler = nil }
        let result = try await MyMemoryTranslator(session: session).translate(text, from: "en", to: "it")
        #expect(result == "Tradotto")
    }
    @Test func rejectsHTTPAndProviderErrors() async {
        let session = session()
        defer { session.invalidateAndCancel(); StubURLProtocol.handler = nil }
        for (status, body) in [(429, "{}"), (200, #"{"responseStatus":403,"responseData":{"translatedText":"Quota exceeded"}}"#), (200, "not json")] {
            StubURLProtocol.handler = { _ in (status, Data(body.utf8)) }
            do {
                _ = try await MyMemoryTranslator(session: session).translate("This is a sentence in English.", from: "en", to: "it")
                Issue.record("Expected translation failure")
            } catch { /* Expected: provider errors must never appear as subtitles. */ }
        }
    }
}
