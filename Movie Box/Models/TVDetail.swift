import Foundation

struct TVDetail: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let voteAverage: Double
    let voteCount: Int
    let firstAirDate: String?
    let genres: [Genre]
    let seasons: [TVSeasonSummary]
    let episodeRunTime: [Int]
    let numberOfSeasons: Int
    let tagline: String?
    let originalLanguage: String?

    var yearText: String { Formatters.year(from: firstAirDate) }
    var runtimeText: String { Formatters.runtime(episodeRunTime.first) }
    var genreLine: String { genres.prefix(3).map(\.name).joined(separator: " · ") }
    var orderedSeasons: [TVSeasonSummary] {
        seasons.sorted { $0.seasonNumber < $1.seasonNumber }
    }

    var summary: MediaSummary {
        MediaSummary(
            id: id,
            title: name,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            releaseDate: firstAirDate,
            genreIDs: genres.map(\.id),
            mediaType: .tv,
            popularity: 0,
            originalLanguage: originalLanguage,
            isAdult: false
        )
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Untitled"
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = MediaSummary.flexibleDouble(container, .voteAverage)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        genres = try container.decodeIfPresent([Genre].self, forKey: .genres) ?? []
        seasons = try container.decodeIfPresent([TVSeasonSummary].self, forKey: .seasons) ?? []
        episodeRunTime = try container.decodeIfPresent([Int].self, forKey: .episodeRunTime) ?? []
        numberOfSeasons = try container.decodeIfPresent(Int.self, forKey: .numberOfSeasons) ?? seasons.count
        tagline = try container.decodeIfPresent(String.self, forKey: .tagline)
        originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(overview, forKey: .overview)
        try container.encodeIfPresent(posterPath, forKey: .posterPath)
        try container.encodeIfPresent(backdropPath, forKey: .backdropPath)
        try container.encode(voteAverage, forKey: .voteAverage)
        try container.encode(voteCount, forKey: .voteCount)
        try container.encodeIfPresent(firstAirDate, forKey: .firstAirDate)
        try container.encode(genres, forKey: .genres)
        try container.encode(seasons, forKey: .seasons)
        try container.encode(episodeRunTime, forKey: .episodeRunTime)
        try container.encode(numberOfSeasons, forKey: .numberOfSeasons)
        try container.encodeIfPresent(tagline, forKey: .tagline)
        try container.encodeIfPresent(originalLanguage, forKey: .originalLanguage)
    }

    private enum CodingKeys: String, CodingKey {
        case id, name, overview, genres, seasons, tagline
        case posterPath = "poster_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case firstAirDate = "first_air_date"
        case episodeRunTime = "episode_run_time"
        case numberOfSeasons = "number_of_seasons"
        case originalLanguage = "original_language"
    }
}

struct TVSeasonSummary: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let seasonNumber: Int
    let episodeCount: Int
    let posterPath: String?

    var displayName: String {
        seasonNumber == 0 ? "Specials" : "Season \(seasonNumber)"
    }

    enum CodingKeys: String, CodingKey {
        case id, name
        case seasonNumber = "season_number"
        case episodeCount = "episode_count"
        case posterPath = "poster_path"
    }
}

struct TVSeasonDetail: Decodable {
    let seasonNumber: Int
    let name: String
    let episodes: [Episode]

    enum CodingKeys: String, CodingKey {
        case name, episodes
        case seasonNumber = "season_number"
    }
}

struct Episode: Identifiable, Hashable, Decodable {
    let id: Int
    let episodeNumber: Int
    let name: String
    let overview: String
    let airDate: String?
    let runtime: Int?
    let stillPath: String?
    let voteAverage: Double

    var progressKey: String { "\(episodeNumber)" }

    enum CodingKeys: String, CodingKey {
        case id, name, overview, runtime
        case episodeNumber = "episode_number"
        case airDate = "air_date"
        case stillPath = "still_path"
        case voteAverage = "vote_average"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? (try container.decode(Int.self, forKey: .episodeNumber))
        episodeNumber = try container.decode(Int.self, forKey: .episodeNumber)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Episode \(episodeNumber)"
        overview = try container.decodeIfPresent(String.self, forKey: .overview) ?? ""
        airDate = try container.decodeIfPresent(String.self, forKey: .airDate)
        runtime = try container.decodeIfPresent(Int.self, forKey: .runtime)
        stillPath = try container.decodeIfPresent(String.self, forKey: .stillPath)
        if let value = try? container.decode(Double.self, forKey: .voteAverage) {
            voteAverage = value
        } else if let value = try? container.decode(Int.self, forKey: .voteAverage) {
            voteAverage = Double(value)
        } else {
            voteAverage = 0
        }
    }
}
