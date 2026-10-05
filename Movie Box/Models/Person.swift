import Foundation

struct PersonSummary: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let profilePath: String?
    let knownForDepartment: String?
    let knownFor: String

    var accessibilitySummary: String {
        var parts = [name]
        if let knownForDepartment, !knownForDepartment.isEmpty {
            parts.append(knownForDepartment)
        }
        return parts.joined(separator: ", ")
    }
}

struct PersonDetail: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let biography: String
    let profilePath: String?
    let knownForDepartment: String?
    let birthday: String?
    let placeOfBirth: String?
    let movieCredits: [MediaSummary]
    let televisionCredits: [MediaSummary]

    var knownForLine: String {
        let titles = (movieCredits + televisionCredits).prefix(3).map(\.title)
        return titles.joined(separator: " · ")
    }
}

struct MultiSearchItem: Decodable {
    let id: Int
    let mediaType: String
    let title: String?
    let name: String?
    let overview: String?
    let posterPath: String?
    let profilePath: String?
    let backdropPath: String?
    let voteAverage: Double
    let voteCount: Int
    let releaseDate: String?
    let firstAirDate: String?
    let genreIDs: [Int]
    let popularity: Double
    let originalLanguage: String?
    let knownForDepartment: String?
    let knownFor: [KnownForTitle]
    let adult: Bool

    struct KnownForTitle: Decodable {
        let title: String?
        let name: String?
    }

    enum CodingKeys: String, CodingKey {
        case id, title, name, overview, popularity, adult
        case mediaType = "media_type"
        case posterPath = "poster_path"
        case profilePath = "profile_path"
        case backdropPath = "backdrop_path"
        case voteAverage = "vote_average"
        case voteCount = "vote_count"
        case releaseDate = "release_date"
        case firstAirDate = "first_air_date"
        case genreIDs = "genre_ids"
        case originalLanguage = "original_language"
        case knownForDepartment = "known_for_department"
        case knownFor = "known_for"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType) ?? "movie"
        title = try container.decodeIfPresent(String.self, forKey: .title)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        overview = try container.decodeIfPresent(String.self, forKey: .overview)
        posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
        voteAverage = MediaSummary.flexibleDouble(container, .voteAverage)
        voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
        releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
        genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
        popularity = MediaSummary.flexibleDouble(container, .popularity)
        originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage)
        knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        knownFor = try container.decodeIfPresent([KnownForTitle].self, forKey: .knownFor) ?? []
        adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
    }

    func searchHit() -> SearchHit? {
        switch mediaType {
        case "person":
            let titles = knownFor.compactMap { $0.title ?? $0.name }.prefix(2).joined(separator: " · ")
            return .person(PersonSummary(
                id: id,
                name: name ?? title ?? "Unknown",
                profilePath: profilePath,
                knownForDepartment: knownForDepartment,
                knownFor: titles
            ))
        case "tv":
            return .media(media(kind: .tv))
        default:
            guard mediaType == "movie" else { return nil }
            return .media(media(kind: .movie))
        }
    }

    private func media(kind: MediaKind) -> MediaSummary {
        MediaSummary(
            id: id,
            title: title ?? name ?? "Untitled",
            overview: overview ?? "",
            posterPath: posterPath,
            backdropPath: backdropPath,
            voteAverage: voteAverage,
            voteCount: voteCount,
            releaseDate: releaseDate ?? firstAirDate,
            genreIDs: genreIDs,
            mediaType: kind,
            popularity: popularity,
            originalLanguage: originalLanguage,
            isAdult: adult
        )
    }
}

enum SearchHit: Identifiable, Hashable {
    case media(MediaSummary)
    case person(PersonSummary)

    var id: String {
        switch self {
        case .media(let media): media.libraryKey
        case .person(let person): "person-\(person.id)"
        }
    }
}
