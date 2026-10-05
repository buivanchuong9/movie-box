import Foundation
import Observation

@MainActor
@Observable
final class MediaMemory {
    static let shared = MediaMemory()
    private var items: [String: MediaSummary] = [:]

    func store(_ media: MediaSummary) {
        items[media.libraryKey] = media
    }

    func media(kind: MediaKind, id: Int) -> MediaSummary? {
        items["\(kind.rawValue)-\(id)"]
    }
}
