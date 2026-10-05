import CryptoKit
import Foundation

actor ResponseCache {
    static let shared = ResponseCache()

    private var memory: [String: Data] = [:]
    private var freshness: [String: Date] = [:]
    private let directory: URL
    private let indexURL: URL

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = caches.appendingPathComponent("lumen-responses", isDirectory: true)
        indexURL = directory.appendingPathComponent("index.json")
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        if let data = try? Data(contentsOf: indexURL),
           let decoded = try? JSONDecoder().decode([String: Date].self, from: data) {
            freshness = decoded
        }
    }

    func store(_ data: Data, for key: String) {
        memory[key] = data
        freshness[key] = Date()
        let file = fileURL(for: key)
        try? data.write(to: file, options: .atomic)
        persistIndex()
    }

    func data(for key: String, maxAge: TimeInterval?) -> Data? {
        if let maxAge, let saved = freshness[key], Date().timeIntervalSince(saved) > maxAge, memory[key] == nil {
            // Freshness applies to memory hits too when a max age is requested.
        }
        if let cached = memory[key] {
            if let maxAge, let saved = freshness[key], Date().timeIntervalSince(saved) > maxAge {
                return nil
            }
            return cached
        }
        let file = fileURL(for: key)
        guard let disk = try? Data(contentsOf: file) else { return nil }
        if let maxAge, let saved = freshness[key], Date().timeIntervalSince(saved) > maxAge {
            return nil
        }
        memory[key] = disk
        return disk
    }

    private func fileURL(for key: String) -> URL {
        let digest = SHA256.hash(data: Data(key.utf8))
        let name = digest.map { String(format: "%02x", $0) }.joined()
        return directory.appendingPathComponent(name)
    }

    private func persistIndex() {
        guard let data = try? JSONEncoder().encode(freshness) else { return }
        try? data.write(to: indexURL, options: .atomic)
    }
}
