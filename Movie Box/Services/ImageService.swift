import Foundation

enum PosterSize: String {
    case small = "w154"
    case medium = "w342"
    case large = "w500"
    case backdrop = "w780"
    case backdropLarge = "w1280"
    case profile = "w185"
    case still = "w300"
}

protocol ImageServiceProtocol {
    func url(path: String?, size: PosterSize) -> URL?
}

struct ImageService: ImageServiceProtocol {
    func url(path: String?, size: PosterSize) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        let normalized = path.hasPrefix("/") ? path : "/\(path)"
        return URL(string: APIConfiguration.imageBaseURL.absoluteString + "/" + size.rawValue + normalized)
    }
}

protocol TrailerServiceProtocol {
    func bestTrailer(from videos: [MediaVideo]) -> MediaVideo?
}

struct TrailerService: TrailerServiceProtocol {
    func bestTrailer(from videos: [MediaVideo]) -> MediaVideo? {
        let youtube = videos.filter { $0.youtubeURL != nil && !$0.key.isEmpty }
        if let official = youtube.first(where: { $0.official && $0.type.caseInsensitiveCompare("Trailer") == .orderedSame }) {
            return official
        }
        if let trailer = youtube.first(where: { $0.type.caseInsensitiveCompare("Trailer") == .orderedSame }) {
            return trailer
        }
        if let teaser = youtube.first(where: { $0.type.caseInsensitiveCompare("Teaser") == .orderedSame }) {
            return teaser
        }
        return youtube.first
    }
}
