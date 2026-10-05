import Foundation

struct CreditsResponse: Decodable, Hashable {
    let cast: [CastMember]
    let crew: [CrewMember]

    var directors: [CrewMember] {
        unique(jobs: ["Director"])
    }

    var writers: [CrewMember] {
        unique(jobs: ["Writer", "Screenplay", "Story", "Teleplay"])
    }

    private func unique(jobs: Set<String>) -> [CrewMember] {
        var seen = Set<Int>()
        return crew.filter { jobs.contains($0.job) }.filter { seen.insert($0.id).inserted }
    }

    private func unique(jobs: [String]) -> [CrewMember] {
        unique(jobs: Set(jobs))
    }
}

struct CastMember: Identifiable, Hashable, Decodable {
    let id: Int
    let name: String
    let character: String
    let profilePath: String?
    let order: Int

    enum CodingKeys: String, CodingKey {
        case id, name, character, order
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        character = try container.decodeIfPresent(String.self, forKey: .character) ?? ""
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
        order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
    }
}

struct CrewMember: Identifiable, Hashable, Decodable {
    let id: Int
    let name: String
    let job: String
    let department: String
    let profilePath: String?

    var rowID: String { "\(id)-\(job)" }

    enum CodingKeys: String, CodingKey {
        case id, name, job, department
        case profilePath = "profile_path"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown"
        job = try container.decodeIfPresent(String.self, forKey: .job) ?? ""
        department = try container.decodeIfPresent(String.self, forKey: .department) ?? ""
        profilePath = try container.decodeIfPresent(String.self, forKey: .profilePath)
    }
}
