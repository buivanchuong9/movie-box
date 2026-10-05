import Foundation

enum AppError: LocalizedError, Equatable {
    case missingAPIKey
    case offline
    case notFound
    case rateLimited
    case server
    case decoding
    case cancelled
    case message(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Movie data is unavailable right now."
        case .offline:
            "You appear to be offline. Saved lists and cached titles are still available."
        case .notFound:
            "That title could not be found."
        case .rateLimited:
            "The metadata service is busy. Try again in a moment."
        case .server:
            "The metadata service did not respond."
        case .decoding:
            "The response could not be read."
        case .cancelled:
            "The request was cancelled."
        case .message(let text):
            text
        }
    }

    var allowsStaleCache: Bool {
        switch self {
        case .offline, .server, .rateLimited, .message:
            true
        case .missingAPIKey, .notFound, .decoding, .cancelled:
            false
        }
    }
}
