import Foundation

struct MovieDetail: Identifiable, Hashable, Codable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let voteCount: Int
    let releaseDate: String?
    let runtime: Int?
    let genres: [Genre]
    let tagline: String?
    let status: String?
    let originalLanguage: String?

    var yearText: String { Formatters.year(from: releaseDate) }
    var runtimeText: String { Formatters.runtime(runtime) }
    var genreLine: String { genres.prefix(3).map(\.name).joined(separator: " · ") }

    var summary: MediaSummary {
        MediaSummary(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            releaseDate: releaseDate,
            genreIDs: genres.map(\.id),
            mediaType: .movie,
            popularity: 0,
            originalLanguage: originalLanguage,
            isAdult: false
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Untitled"
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = MediaSummary.flexibleDouble(container, .voteAverage)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        genres = try container.decodeIfPresent([Genre].self, forKey: .genres) ?? []
        tagline = try container.decodeIfPresent(String.self, forKey: .tagline)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage)
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
        try container.encodeIfPresent(runtime, forKey: .runtime)
        try container.encode(genres, forKey: .genres)
        try container.encodeIfPresent(tagline, forKey: .tagline)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(originalLanguage, forKey: .originalLanguage)
    }

    private enum CodingKeys: String, CodingKey {
        case id, title, overview, runtime, genres, tagline, status
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case originalLanguage = "original_language"
    }
}
