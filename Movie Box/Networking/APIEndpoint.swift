import Foundation

struct APICredential: Equatable {
    var apiKey: String
    var bearerToken: String

    var isConfigured: Bool {
        !apiKey.isEmpty || !bearerToken.isEmpty
    }
}

enum APIConfiguration {
    static let baseURL = URL(string: "https://api.themoviedb.org/3")!
    static let imageBaseURL = URL(string: "https://image.tmdb.org/t/p")!

    static let keyAccount = "tmdb_api_key"
    static let tokenAccount = "tmdb_access_token"

    static func current() -> APICredential {
        let keychainKey = sanitized(KeychainStore.read(account: keyAccount))
        let keychainToken = sanitized(KeychainStore.read(account: tokenAccount))
        let info = Bundle.main.infoDictionary
        let plistKey = sanitized(info?["TMDB_API_KEY"] as? String)
        let plistToken = sanitized(info?["TMDB_ACCESS_TOKEN"] as? String)
        let env = ProcessInfo.processInfo.environment
        let envKey = sanitized(env["TMDB_API_KEY"])
        let envToken = sanitized(env["TMDB_ACCESS_TOKEN"])
        return APICredential(
            apiKey: keychainKey ?? plistKey ?? envKey ?? "",
            bearerToken: keychainToken ?? plistToken ?? envToken ?? ""
        )
    }

    private static func sanitized(_ raw: String?) -> String? {
        guard var value = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if value.contains("$(") || value == "YOUR_KEY" { return nil }
        if value.hasPrefix("=") { value.removeFirst() }
        value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}

enum APIEndpoint {
    case trendingMovies(page: Int)
    case trendingTV(page: Int)
    case popularMovies(page: Int)
    case topRatedMovies(page: Int)
    case nowPlaying(page: Int)
    case upcoming(page: Int)
    case popularTV(page: Int)
    case topRatedTV(page: Int)
    case movie(id: Int)
    case movieCredits(id: Int)
    case movieVideos(id: Int)
    case movieReviews(id: Int, page: Int)
    case movieSimilar(id: Int, page: Int)
    case tv(id: Int)
    case tvCredits(id: Int)
    case tvVideos(id: Int)
    case tvReviews(id: Int, page: Int)
    case tvSimilar(id: Int, page: Int)
    case tvSeason(id: Int, season: Int)
    case searchMulti(query: String, page: Int)
    case searchMovies(query: String, page: Int)
    case searchTV(query: String, page: Int)
    case searchPeople(query: String, page: Int)
    case person(id: Int)
    case personCredits(id: Int)
    case movieGenres
    case discoverMovies(MediaFilters, page: Int)
    case discoverTV(MediaFilters, page: Int)

    var path: String {
        switch self {
        case .trendingMovies: "/trending/movie/week"
        case .trendingTV: "/trending/tv/week"
        case .popularMovies: "/movie/popular"
        case .topRatedMovies: "/movie/top_rated"
        case .nowPlaying: "/movie/now_playing"
        case .upcoming: "/movie/upcoming"
        case .popularTV: "/tv/popular"
        case .topRatedTV: "/tv/top_rated"
        case .movie(let id): "/movie/\(id)"
        case .movieCredits(let id): "/movie/\(id)/credits"
        case .movieVideos(let id): "/movie/\(id)/videos"
        case .movieReviews(let id, _): "/movie/\(id)/reviews"
        case .movieSimilar(let id, _): "/movie/\(id)/similar"
        case .tv(let id): "/tv/\(id)"
        case .tvCredits(let id): "/tv/\(id)/credits"
        case .tvVideos(let id): "/tv/\(id)/videos"
        case .tvReviews(let id, _): "/tv/\(id)/reviews"
        case .tvSimilar(let id, _): "/tv/\(id)/similar"
        case .tvSeason(let id, let season): "/tv/\(id)/season/\(season)"
        case .searchMulti: "/search/multi"
        case .searchMovies: "/search/movie"
        case .searchTV: "/search/tv"
        case .searchPeople: "/search/person"
        case .person(let id): "/person/\(id)"
        case .personCredits(let id): "/person/\(id)/combined_credits"
        case .movieGenres: "/genre/movie/list"
        case .discoverMovies: "/discover/movie"
        case .discoverTV: "/discover/tv"
        }
    }

    var cacheMaxAge: TimeInterval {
        switch self {
        case .movie, .tv, .person, .movieCredits, .tvCredits, .personCredits, .tvSeason:
            60 * 60 * 12
        case .movieVideos, .tvVideos, .movieReviews, .tvReviews:
            60 * 60 * 6
        default:
            60 * 20
        }
    }

    func queryItems(language: String, filters: MediaFilters? = nil, page: Int? = nil, query: String? = nil) -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "language", value: language),
            URLQueryItem(name: "include_adult", value: "false")
        ]
        if let page {
            items.append(URLQueryItem(name: "page", value: "\(page)"))
        }
        if let query {
            items.append(URLQueryItem(name: "query", value: query))
        }
        if let filters {
            let sortValue = isTVDiscover && filters.sort == .releaseDate ? "first_air_date.desc" : filters.sort.tmdbValue
            items.append(URLQueryItem(name: "sort_by", value: sortValue))
            if let genreID = filters.genreID {
                items.append(URLQueryItem(name: "with_genres", value: "\(genreID)"))
            }
            if let year = filters.year {
                let key = self.isTVDiscover ? "first_air_date_year" : "primary_release_year"
                items.append(URLQueryItem(name: key, value: "\(year)"))
            }
            if let minimumRating = filters.minimumRating {
                items.append(URLQueryItem(name: "vote_average.gte", value: String(minimumRating)))
                items.append(URLQueryItem(name: "vote_count.gte", value: "50"))
            }
            if let language = filters.language {
                items.append(URLQueryItem(name: "with_original_language", value: language))
            }
            if let country = filters.country {
                items.append(URLQueryItem(name: "with_origin_country", value: country))
            }
        }
        return items
    }

    private var isTVDiscover: Bool {
        if case .discoverTV = self { return true }
        return false
    }

    func cacheKey(language: String) -> String {
        let items = resolvedQuery(language: language)
            .map { "\($0.name)=\($0.value ?? "")" }
            .sorted()
            .joined(separator: "&")
        return "\(path)?\(items)"
    }

    func resolvedQuery(language: String) -> [URLQueryItem] {
        switch self {
        case .trendingMovies(let page), .trendingTV(let page), .popularMovies(let page),
             .topRatedMovies(let page), .nowPlaying(let page), .upcoming(let page),
             .popularTV(let page), .topRatedTV(let page):
            queryItems(language: language, page: page)
        case .movie, .tv, .movieCredits, .tvCredits, .movieVideos, .tvVideos, .person, .movieGenres:
            queryItems(language: language)
        case .movieReviews(_, let page), .tvReviews(_, let page), .movieSimilar(_, let page), .tvSimilar(_, let page):
            queryItems(language: language, page: page)
        case .tvSeason:
            queryItems(language: language)
        case .searchMulti(let query, let page), .searchMovies(let query, let page),
             .searchTV(let query, let page), .searchPeople(let query, let page):
            queryItems(language: language, page: page, query: query)
        case .personCredits:
            queryItems(language: language)
        case .discoverMovies(let filters, let page), .discoverTV(let filters, let page):
            queryItems(language: language, filters: filters, page: page)
        }
    }
}
