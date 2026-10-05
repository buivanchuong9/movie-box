import Foundation

protocol PersonServiceProtocol {
    func details(id: Int) async throws -> PersonDetail
}

final class PersonService: PersonServiceProtocol {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func details(id: Int) async throws -> PersonDetail {
        let profile: PersonDTO = try await client.get(.person(id: id))
        let filmography: CombinedCreditsDTO? = try? await client.get(.personCredits(id: id))
        let pool = (filmography?.cast ?? []) + (filmography?.crew ?? [])
        let movies = Self.unique(pool.filter { $0.mediaType == "movie" && !$0.adult }.map(\.summary))
        let shows = Self.unique(pool.filter { $0.mediaType == "tv" && !$0.adult }.map(\.summary))
        return PersonDetail(
            id: profile.id,
            name: profile.name,
            biography: profile.biography,
            profilePath: profile.profilePath,
            knownForDepartment: profile.knownForDepartment,
            birthday: profile.birthday,
            placeOfBirth: profile.placeOfBirth,
            movieCredits: movies,
            televisionCredits: shows
        )
    }

    private static func unique(_ items: [MediaSummary]) -> [MediaSummary] {
        var seen = Set<String>()
        return items
            .sorted { $0.popularity > $1.popularity }
            .filter { seen.insert($0.libraryKey).inserted }
            .prefix(40)
            .map { $0 }
    }
}

private struct PersonDTO: Decodable {
    let id: Int
    let name: String
    let biography: String
    let profilePath: String?
    let knownForDepartment: String?
    let birthday: String?
    let placeOfBirth: String?

    enum CodingKeys: String, CodingKey {
        case id, name, biography, birthday
        case profilePath = "profile_path"
        case knownForDepartment = "known_for_department"
        case placeOfBirth = "place_of_birth"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        biography = try container.decodeIfPresent(String.self, forKey: .biography) ?? ""
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        knownForDepartment = try container.decodeIfPresent(String.self, forKey: .knownForDepartment)
        birthday = try container.decodeIfPresent(String.self, forKey: .birthday)
        placeOfBirth = try container.decodeIfPresent(String.self, forKey: .placeOfBirth)
    }
}

private struct CombinedCreditsDTO: Decodable {
    let cast: [CreditItem]
    let crew: [CreditItem]

    enum CodingKeys: String, CodingKey { case cast, crew }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cast = try container.decodeIfPresent([CreditItem].self, forKey: .cast) ?? []
        crew = try container.decodeIfPresent([CreditItem].self, forKey: .crew) ?? []
    }

    struct CreditItem: Decodable {
        let id: Int
        let title: String?
        let name: String?
        let overview: String?
        let posterPath: String?
        let backdropPath: String?
        let mediaType: String
        let voteAverage: Double
        let voteCount: Int
        let releaseDate: String?
        let firstAirDate: String?
        let genreIDs: [Int]
        let popularity: Double
        let originalLanguage: String?
        let adult: Bool

        var summary: MediaSummary {
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
                mediaType: mediaType == "tv" ? .tv : .movie,
                popularity: popularity,
                originalLanguage: originalLanguage,
                isAdult: adult
            )
        }

        enum CodingKeys: String, CodingKey {
            case id, title, name, overview, popularity, adult
            case posterPath = "poster_path"
            case backdropPath = "backdrop_path"
            case mediaType = "media_type"
            case voteAverage = "vote_average"
            case voteCount = "vote_count"
            case releaseDate = "release_date"
            case firstAirDate = "first_air_date"
            case genreIDs = "genre_ids"
            case originalLanguage = "original_language"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = try container.decode(Int.self, forKey: .id)
            title = try container.decodeIfPresent(String.self, forKey: .title)
            name = try container.decodeIfPresent(String.self, forKey: .name)
            overview = try container.decodeIfPresent(String.self, forKey: .overview)
            posterPath = try container.decodeIfPresent(String.self, forKey: .posterPath)
            backdropPath = try container.decodeIfPresent(String.self, forKey: .backdropPath)
            mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType) ?? "movie"
            voteAverage = MediaSummary.flexibleDouble(container, .voteAverage)
            voteCount = try container.decodeIfPresent(Int.self, forKey: .voteCount) ?? 0
            releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
            firstAirDate = try container.decodeIfPresent(String.self, forKey: .firstAirDate)
            genreIDs = try container.decodeIfPresent([Int].self, forKey: .genreIDs) ?? []
            popularity = MediaSummary.flexibleDouble(container, .popularity)
            originalLanguage = try container.decodeIfPresent(String.self, forKey: .originalLanguage)
            adult = try container.decodeIfPresent(Bool.self, forKey: .adult) ?? false
        }
    }
}
