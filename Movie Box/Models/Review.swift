import Foundation

struct MovieReview: Identifiable, Hashable, Codable {
    let id: String
    let author: String
    let username: String?
    let content: String
    let rating: Double?
    let createdAt: Date?
    let updatedAt: Date?
    let avatarPath: String?
    let url: URL?

    var displayName: String {
        let name = author.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        if let username {
            let handle = username.trimmingCharacters(in: .whitespacesAndNewlines)
            if !handle.isEmpty { return handle }
        }
        return "Reviewer"
    }

    var sourceURL: URL? {
        guard let url, url.scheme?.lowercased() == "https" else { return nil }
        return url
    }

    var avatarURL: URL? {
        guard let avatarPath, !avatarPath.isEmpty else { return nil }
        let trimmed = avatarPath.hasPrefix("/") ? String(avatarPath.dropFirst()) : avatarPath
        if trimmed.hasPrefix("https://") || trimmed.hasPrefix("http://") {
            return URL(string: trimmed)
        }
        return ImageService().url(path: "/" + trimmed, size: .profile)
    }

    enum CodingKeys: String, CodingKey {
        case id, author, content, url, username, rating
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case avatarPath = "avatar_path"
        case authorDetails = "author_details"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let rawID = try container.decodeIfPresent(String.self, forKey: .id), !rawID.isEmpty else {
            throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Missing review id")
        }
        id = rawID
        author = try container.decodeIfPresent(String.self, forKey: .author) ?? ""
        content = try container.decodeIfPresent(String.self, forKey: .content) ?? ""
        let details = try container.decodeIfPresent(AuthorDetails.self, forKey: .authorDetails)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? details?.username
        if let value = try? container.decode(Double.self, forKey: .rating) {
            rating = value
        } else if let value = try? container.decode(Int.self, forKey: .rating) {
            rating = Double(value)
        } else {
            rating = details?.rating
        }
        avatarPath = try container.decodeIfPresent(String.self, forKey: .avatarPath) ?? details?.avatarPath
        createdAt = Self.decodeDate(container, .createdAt)
        updatedAt = Self.decodeDate(container, .updatedAt)
        if let raw = try container.decodeIfPresent(String.self, forKey: .url), let parsed = URL(string: raw) {
            url = parsed
        } else {
            url = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(author, forKey: .author)
        try container.encode(content, forKey: .content)
        try container.encodeIfPresent(username, forKey: .username)
        try container.encodeIfPresent(rating, forKey: .rating)
        try container.encodeIfPresent(avatarPath, forKey: .avatarPath)
        try container.encodeIfPresent(url?.absoluteString, forKey: .url)
        if let createdAt { try container.encode(Self.format(createdAt), forKey: .createdAt) }
        if let updatedAt { try container.encode(Self.format(updatedAt), forKey: .updatedAt) }
    }

    private struct AuthorDetails: Decodable {
        let username: String?
        let avatarPath: String?
        let rating: Double?

        enum CodingKeys: String, CodingKey {
            case username, rating
            case avatarPath = "avatar_path"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            username = try container.decodeIfPresent(String.self, forKey: .username)
            avatarPath = try container.decodeIfPresent(String.self, forKey: .avatarPath)
            if let value = try? container.decode(Double.self, forKey: .rating) {
                rating = value
            } else if let value = try? container.decode(Int.self, forKey: .rating) {
                rating = Double(value)
            } else if let value = try? container.decode(String.self, forKey: .rating), let number = Double(value) {
                rating = number
            } else {
                rating = nil
            }
        }
    }

    private static func decodeDate(_ container: KeyedDecodingContainer<CodingKeys>, _ key: CodingKeys) -> Date? {
        guard let raw = try? container.decode(String.self, forKey: key) else { return nil }
        return parse(raw)
    }

    private static func parse(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }
        let basic = ISO8601DateFormatter()
        basic.formatOptions = [.withInternetDateTime]
        return basic.date(from: raw)
    }

    private static func format(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }
}

struct CachedReviews: Codable, Equatable {
    let reviews: [MovieReview]
    let page: Int
    let totalPages: Int
}

struct ReviewList: Decodable {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let results: [MovieReview]

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        page = try container.decodeIfPresent(Int.self, forKey: .page) ?? 1
        totalPages = try container.decodeIfPresent(Int.self, forKey: .totalPages) ?? 1
        totalResults = try container.decodeIfPresent(Int.self, forKey: .totalResults) ?? 0
        let wrapped = try container.decodeIfPresent([LooseReview].self, forKey: .results) ?? []
        results = wrapped.compactMap(\.review)
    }

    private struct LooseReview: Decodable {
        let review: MovieReview?

        init(from decoder: Decoder) throws {
            review = try? MovieReview(from: decoder)
        }
    }
}
