import CryptoKit
import Foundation
import ImageIO
import UIKit

actor ImageStore {
    static let shared = ImageStore()

    private var memory: [String: Data] = [:]
    private let directory: URL
    private let session: URLSession

    init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        directory = caches.appendingPathComponent("lumen-images", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.timeoutIntervalForRequest = 20
        session = URLSession(configuration: configuration)
    }

    func data(for url: URL, maxPixel: CGFloat) async throws -> Data {
        let key = cacheKey(url: url, maxPixel: maxPixel)
        if let cached = memory[key] {
            return cached
        }
        let file = directory.appendingPathComponent(key)
        if let disk = try? Data(contentsOf: file), !disk.isEmpty {
            remember(disk, for: key)
            return disk
        }

        let (raw, response) = try await session.data(from: url)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw AppError.server
        }
        let prepared = Self.downsample(raw, maxPixel: maxPixel) ?? raw
        remember(prepared, for: key)
        try? prepared.write(to: file, options: .atomic)
        return prepared
    }

    private func remember(_ data: Data, for key: String) {
        if memory.count > 180 {
            memory.removeAll(keepingCapacity: true)
        }
        memory[key] = data
    }

    private func cacheKey(url: URL, maxPixel: CGFloat) -> String {
        let digest = SHA256.hash(data: Data("\(url.absoluteString)#\(Int(maxPixel))".utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func downsample(_ data: Data, maxPixel: CGFloat) -> Data? {
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else { return nil }
        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ] as CFDictionary
        guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil) else {
            return nil
        }
        CGImageDestinationAddImage(destination, image, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return output as Data
    }
}
