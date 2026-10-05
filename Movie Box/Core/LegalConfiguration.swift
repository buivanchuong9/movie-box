import Foundation

enum LegalConfiguration {
    static var termsURL: URL? { httpsURL(forInfoKey: "LUMEN_TERMS_URL") }
    static var privacyURL: URL? { httpsURL(forInfoKey: "LUMEN_PRIVACY_URL") }

    private static func httpsURL(forInfoKey key: String) -> URL? {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$("),
              let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https"
        else { return nil }
        return url
    }
}
