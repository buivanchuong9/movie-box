import Foundation

struct MediaVideo: Identifiable, Hashable, Decodable {
    let id: String
    let key: String
    let name: String
    let site: String
    let type: String
    let official: Bool

    var youtubeURL: URL? {
        guard site.caseInsensitiveCompare("YouTube") == .orderedSame else { return nil }
        return URL(string: "https://www.youtube.com/watch?v=\(key)")
    }

    enum CodingKeys: String, CodingKey {
        case id, key, name, site, type, official
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        key = try container.decodeIfPresent(String.self, forKey: .key) ?? ""
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Trailer"
        site = try container.decodeIfPresent(String.self, forKey: .site) ?? ""
        type = try container.decodeIfPresent(String.self, forKey: .type) ?? ""
        official = try container.decodeIfPresent(Bool.self, forKey: .official) ?? false
    }
}

struct VideoList: Decodable {
    let results: [MediaVideo]
}

struct GenreList: Decodable {
    let genres: [Genre]
}
