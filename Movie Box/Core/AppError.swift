import Foundation

enum AppError: LocalizedError, Equatable {
    case offline
    case notFound
    case rateLimited
    case server
    case decoding
    case cancelled
    case message(String)

    var errorDescription: String? {
        switch self {
        case .offline:
            "You appear to be offline. Saved lists and cached titles are still available."
        case .notFound:
            "That title could not be found."
        case .rateLimited:
            "Please try again in a moment."
        case .server:
            "Something went wrong. Please try again."
        case .decoding:
            "The response could not be read."
        case .cancelled:
            "The request was cancelled."
        case .message(let text):
            text
        }
    }

    static func userMessage(for error: Error) -> String {
        if let app = error as? AppError, let text = app.errorDescription {
            return text
        }
        return "Something went wrong. Please try again."
    }

    var allowsStaleCache: Bool {
        switch self {
        case .offline, .server, .rateLimited, .message:
            true
        case .notFound, .decoding, .cancelled:
            false
        }
    }
}
