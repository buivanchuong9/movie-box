import Foundation

enum LegalDocument: String, Hashable, Identifiable {
    case privacy
    case terms
    case about

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: "Privacy"
        case .terms: "Terms"
        case .about: "About"
        }
    }
}

enum CatalogSource: String, Hashable, Codable {
    case trending
    case popular
    case topRated
    case nowPlaying
    case upcoming
    case popularTV
    case topRatedTV
    case forYou
}

struct CatalogQuery: Hashable {
    var title: String
    var source: CatalogSource
    var genreID: Int?
    var year: Int?
}

enum AppRoute: Hashable {
    case movie(id: Int)
    case television(id: Int)
    case person(id: Int)
    case catalog(CatalogQuery)
    case settings
    case premium
    case statistics
    case legal(LegalDocument)

    static func media(_ item: MediaSummary) -> AppRoute {
        item.mediaType == .tv ? .television(id: item.id) : .movie(id: item.id)
    }
}
