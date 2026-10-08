import Foundation

enum SortOption: String, CaseIterable, Identifiable, Hashable {
    case popularity
    case rating
    case releaseDate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .popularity: "Popularity"
        case .rating: "Rating"
        case .releaseDate: "Release Date"
        }
    }

    var tmdbValue: String {
        switch self {
        case .popularity: "popularity.desc"
        case .rating: "vote_average.desc"
        case .releaseDate: "primary_release_date.desc"
        }
    }
}

struct MediaFilters: Equatable, Hashable {
    var genreID: Int?
    var year: Int?
    var minimumRating: Double?
    var language: String?
    var country: String?
    var sort: SortOption = .popularity

    var isActive: Bool {
        activeCount > 0 || sort != .popularity
    }

    var activeCount: Int {
        [genreID != nil, year != nil, minimumRating != nil, language != nil, country != nil].filter { $0 }.count
    }

    func allows(_ item: MediaSummary) -> Bool {
        if let genreID, !item.genreIDs.contains(genreID) { return false }
        if let year {
            let itemYear = Int(item.yearText)
            if itemYear != year { return false }
        }
        if let minimumRating, item.voteAverage < minimumRating { return false }
        if let language, item.originalLanguage != language { return false }
        return true
    }
}

enum SearchScope: String, CaseIterable, Identifiable {
    case all
    case movies
    case tv
    case people

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .movies: "Movies"
        case .tv: "TV"
        case .people: "People"
        }
    }
}

enum LibrarySegment: String, CaseIterable, Identifiable {
    case watchlist
    case favorites
    case watched

    var id: String { rawValue }

    var title: String {
        switch self {
        case .watchlist: "Watchlist"
        case .favorites: "Favorites"
        case .watched: "Watched"
        }
    }
}

enum AppearancePreference: String, CaseIterable, Identifiable, Codable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
}
