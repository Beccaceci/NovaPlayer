import Foundation
import Translation

public protocol SubtitleTranslating {
    func translate(_ text: String, from source: String, to language: String) async throws -> String
    func translate(_ text: String, from source: String, to language: String, allowOnline: Bool) async throws -> String
}

public extension SubtitleTranslating {
    func translate(_ text: String, from source: String, to language: String, allowOnline: Bool) async throws -> String {
        // Unknown injected providers are treated as potentially online.
        guard allowOnline else { throw OfflineTranslationError.unavailable }
        return try await translate(text, from: source, to: language)
    }
}

public struct MyMemoryTranslator: SubtitleTranslating {
    private let session: URLSession
    public init(session: URLSession = .shared) { self.session = session }

    public func translate(_ text: String, from source: String, to language: String) async throws -> String {
        guard text.utf8.count <= 500 else {
            throw URLError(.badURL)
        }
        if source == language { return text }
        var components = URLComponents(string: "https://api.mymemory.translated.net/get")!
        components.queryItems = [URLQueryItem(name: "q", value: text),
                                URLQueryItem(name: "langpair", value: "\(source)|\(language)")]
        var request = URLRequest(url: components.url!)
        request.timeoutInterval = 15
        let (data, response) = try await session.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        let result = try JSONDecoder().decode(Response.self, from: data)
        guard result.responseStatus == 200, !result.responseData.translatedText.isEmpty else {
            throw URLError(.cannotParseResponse)
        }
        return result.responseData.translatedText
    }

    private struct Response: Decodable {
        let responseStatus: Int
        let responseData: Translation
        struct Translation: Decodable { let translatedText: String }
    }
}

public enum OfflineTranslationError: Error {
    case unavailable
}

/// Uses installed language resources only. Downloads are a separate user action.
public struct AppleOfflineTranslator: SubtitleTranslating {
    public init() {}

    public func translate(_ text: String, from source: String, to language: String) async throws -> String {
        guard Set(["en", "it"]).isSuperset(of: [source, language]) else {
            throw OfflineTranslationError.unavailable
        }
        if source == language { return text }
        // Xcode 16 can still build the online fallback for the macOS 14 baseline.
        #if compiler(>=6.2)
        if #available(macOS 26, *) {
            let sourceLocale = Locale.Language(identifier: source)
            let targetLocale = Locale.Language(identifier: language)
            guard await LanguageAvailability().status(from: sourceLocale, to: targetLocale) == .installed else {
                throw OfflineTranslationError.unavailable
            }
            try Task.checkCancellation()
            let session: TranslationSession
            #if compiler(>=6.3)
            if #available(macOS 26.4, *) {
                session = TranslationSession(installedSource: sourceLocale, target: targetLocale,
                                             preferredStrategy: .lowLatency)
            } else {
                session = TranslationSession(installedSource: sourceLocale, target: targetLocale)
            }
            #else
            session = TranslationSession(installedSource: sourceLocale, target: targetLocale)
            #endif
            let response = try await session.translate(text)
            try Task.checkCancellation()
            return response.targetText
        }
        #endif
        throw OfflineTranslationError.unavailable
    }
}

public struct OfflineFirstTranslator: SubtitleTranslating {
    private let offline: SubtitleTranslating
    private let online: SubtitleTranslating

    public init(offline: SubtitleTranslating = AppleOfflineTranslator(),
                online: SubtitleTranslating = MyMemoryTranslator()) {
        self.offline = offline
        self.online = online
    }

    public func translate(_ text: String, from source: String, to language: String) async throws -> String {
        try await translate(text, from: source, to: language, allowOnline: true)
    }

    public func translate(_ text: String, from source: String, to language: String,
                          allowOnline: Bool) async throws -> String {
        try Task.checkCancellation()
        if source == language { return text }
        do {
            return try await offline.translate(text, from: source, to: language)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            guard allowOnline else { throw error }
            return try await online.translate(text, from: source, to: language)
        }
    }
}
