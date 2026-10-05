import Foundation

enum MediaKind: String, Codable, Hashable {
    case movie
    case tv
    case person
}

struct Genre: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
}

struct MediaSummary: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let voteCount: Int
    let releaseDate: String?
    let genreIDs: [Int]
    let mediaType: MediaKind
    let popularity: Double
    let originalLanguage: String?
    let isAdult: Bool

    var libraryKey: String { "\(mediaType.rawValue)-\(id)" }
    var yearText: String { Formatters.year(from: releaseDate) }
    var ratingText: String { Formatters.rating(voteAverage) }

    var genreLine: String {
        let names = genreIDs.prefix(2).compactMap { GenreCatalog.name(for: $0) }
        return names.joined(separator: " · ")
    }

    var shareText: String {
        let year = yearText == "—" ? "" : " (\(yearText))"
        let rating = voteAverage > 0 ? " · \(ratingText)/10" : ""
        return "\(title)\(year)\(rating) — discovered on Lumen"
    }

    var accessibilitySummary: String {
        var parts = [title]
        if yearText != "—" { parts.append(yearText) }
        if voteAverage > 0 { parts.append("rated \(ratingText) out of 10") }
        if !genreLine.isEmpty { parts.append(genreLine) }
        return parts.joined(separator: ", ")
    }

    func setting(kind: MediaKind) -> MediaSummary {
        MediaSummary(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            releaseDate: releaseDate,
            genreIDs: genreIDs,
            mediaType: kind,
            popularity: popularity,
            originalLanguage: originalLanguage,
            isAdult: isAdult
        )
    }

    init(
        id: Int,
        title: String,
        overview: String,
        posterPath: String?,
        backdropPath: String?,
        voteAverage: Double,
        voteCount: Int,
        releaseDate: String?,
        genreIDs: [Int],
        mediaType: MediaKind,
        popularity: Double,
        originalLanguage: String?,
        isAdult: Bool
    ) {
        self.id = id
        self.title = title
        self.overview = overview
        self.posterPath = posterPath
        self.backdropPath = backdropPath
        self.voteAverage = voteAverage
        self.voteCount = voteCount
        self.releaseDate = releaseDate
        self.genreIDs = genreIDs
        self.mediaType = mediaType
        self.popularity = popularity
        self.originalLanguage = originalLanguage
        self.isAdult = isAdult
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        let decodedTitle = try container.decodeIfPresent(String.self, forKey: .title)
        let decodedName = try container.decodeIfPresent(String.self, forKey: .name)
        title = decodedTitle ?? decodedName ?? "Untitled"
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = Self.clean(try container.decodeIfPresent(String.self, forKey: .posterPath))
        backdropPath = Self.clean(try container.decodeIfPresent(String.self, forKey: .backdropPath))
        voteAverage = Self.flexibleDouble(container, .voteAverage)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        let release = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        let air = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        releaseDate = Self.clean(release ?? air)
        genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
        if let raw = try container.decodeIfPresent(String.self, forKey: .mediaType),
           let kind = MediaKind(rawValue: raw), kind != .person {
            mediaType = kind
        } else if decodedName != nil && decodedTitle == nil {
            mediaType = .tv
        } else {
            mediaType = .movie
        }
        popularity = Self.flexibleDouble(container, .popularity)
        originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage)
        isAdult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(overview, forKey: .overview)
        try container.encodeIfPresent(posterPath, forKey: .posterPath)
        try container.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try container.encode(voteAverage, forKey: .voteAverage)
        try container.encode(voteCount, forKey: .voteCount)
        try container.encodeIfPresent(releaseDate, forKey: .releaseDate)
        try container.encode(genreIDs, forKey: .genreIDs)
        try container.encode(mediaType.rawValue, forKey: .mediaType)
        try container.encode(popularity, forKey: .popularity)
        try container.encodeIfPresent(originalLanguage, forKey: .originalLanguage)
        try container.encode(isAdult, forKey: .adult)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, name, overview, popularity, adult
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
        case mediaType = "media_type"
        case originalLanguage = "original_language"
    }

    private static func clean(_ value: String?) -> String? {
        guard let value, !value.isEmpty else { return nil }
        return value
    }

    static func flexibleDouble<Key: CodingKey>(_ container: KeyedDecodingContainer<Key>, _ key: Key) -> Double {
        if let value = try? container.decode(Double.self, forKey: key) { return value }
        if let value = try? container.decode(Int.self, forKey: key) { return Double(value) }
        return 0
    }
}

struct PagedResult<Item> {
    let page: Int
    let totalPages: Int
    let totalResults: Int
    let items: [Item]

    var hasMore: Bool { page < totalPages }
}

struct PagedPayload<Item: Decodable>: Decodable {
    let page: Int
    let results: [Item]
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case page, results
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}
