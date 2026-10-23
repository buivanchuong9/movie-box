import Foundation

enum LegalConfiguration {
    static let termsKey = "LUMEN_TERMS_URL"
    static let privacyKey = "LUMEN_PRIVACY_URL"

    static var termsURL: URL? { resolve(termsKey) }
    static var privacyURL: URL? { resolve(privacyKey) }

    /// Resolves an HTTPS URL from Info.plist. Returns nil for missing, unexpanded, non-HTTPS or host-less values.
    /// The in-app text is the only fallback; no URL is ever guessed or substituted.
    static func url(from raw: String?) -> URL? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty, !trimmed.contains("$("),
              let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https",
              let host = url.host, host.contains(".")
        else { return nil }
        return url
    }

    private static func resolve(_ key: String) -> URL? {
        let url = url(from: Bundle.main.object(forInfoDictionaryKey: key) as? String)
        #if DEBUG
        if url == nil {
            assertionFailure("\(key) is missing or invalid in Config/Secrets.xcconfig; legal links will not open a web page.")
        }
        #endif
        return url
    }
}
