import Foundation
import os

enum RequestCache {
    @TaskLocal static var bypassFreshness = false
}

final class APIClient {
    private let session: URLSession
    private let cache: ResponseCache
    private let decoder = JSONDecoder()
    var contentLanguage: String = "en-US"
    var credential: () -> APICredential

    init(cache: ResponseCache = .shared, credential: @escaping () -> APICredential = APIConfiguration.current) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20
        configuration.waitsForConnectivity = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        session = URLSession(configuration: configuration)
        self.cache = cache
        self.credential = credential
    }

    func get<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        let credentials = credential()
        guard credentials.isConfigured else {
            debugLog(endpoint: endpoint, auth: "none", status: nil, bytes: 0, message: "credential_missing")
            throw AppError.missingAPIKey
        }
        let key = endpoint.cacheKey(language: contentLanguage)
        if !RequestCache.bypassFreshness,
           let fresh = await cache.data(for: key, maxAge: endpoint.cacheMaxAge),
           let decoded = try? decoder.decode(T.self, from: fresh) {
            return decoded
        }
        do {
            let data = try await fetch(endpoint, credentials: credentials)
            await cache.store(data, for: key)
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw AppError.decoding
            }
        } catch let error as AppError where error == .cancelled {
            throw error
        } catch is CancellationError {
            throw AppError.cancelled
        } catch let error as AppError {
            if error.allowsStaleCache, let stale = await cache.data(for: key, maxAge: nil) {
                if let decoded = try? decoder.decode(T.self, from: stale) {
                    return decoded
                }
            }
            throw error
        } catch {
            if let stale = await cache.data(for: key, maxAge: nil),
               let decoded = try? decoder.decode(T.self, from: stale) {
                return decoded
            }
            throw AppError.offline
        }
    }

    private func fetch(_ endpoint: APIEndpoint, credentials: APICredential) async throws -> Data {
        var lastError: Error = AppError.server
        for attempt in 0..<3 {
            try Task.checkCancellation()
            do {
                return try await perform(endpoint, credentials: credentials)
            } catch is CancellationError {
                throw AppError.cancelled
            } catch let error as URLError where error.code == .cancelled {
                throw AppError.cancelled
            } catch let error as AppError where error == .cancelled {
                throw error
            } catch let error as AppError where !error.allowsStaleCache {
                throw error
            } catch {
                lastError = error
                if attempt < 2 {
                    try? await Task.sleep(for: .milliseconds(280 * (attempt + 1)))
                }
            }
        }
        throw lastError
    }

    private func perform(_ endpoint: APIEndpoint, credentials: APICredential) async throws -> Data {
        let root = APIConfiguration.baseURL.absoluteString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let path = endpoint.path.hasPrefix("/") ? endpoint.path : "/\(endpoint.path)"
        guard var components = URLComponents(string: root + path) else {
            throw AppError.message("The request could not be built.")
        }
        var items = endpoint.resolvedQuery(language: contentLanguage)
        if credentials.bearerToken.isEmpty {
            items.append(URLQueryItem(name: "api_key", value: credentials.apiKey))
        }
        components.queryItems = items
        guard let url = components.url else { throw AppError.message("The request could not be built.") }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if !credentials.bearerToken.isEmpty {
            request.setValue("Bearer \(credentials.bearerToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await session.data(for: request)
        try Task.checkCancellation()
        guard let http = response as? HTTPURLResponse else {
            debugLog(endpoint: endpoint, auth: authMode(credentials), status: nil, bytes: data.count, message: "non_http_response")
            throw AppError.server
        }
        debugLog(
            endpoint: endpoint,
            auth: authMode(credentials),
            status: http.statusCode,
            bytes: data.count,
            message: http.statusCode < 300 ? "" : Self.apiMessage(from: data)
        )
        switch http.statusCode {
        case 200..<300:
            return data
        case 401, 403:
            throw AppError.missingAPIKey
        case 404:
            throw AppError.notFound
        case 429:
            throw AppError.rateLimited
        case 500..<600:
            throw AppError.server
        default:
            throw AppError.server
        }
    }

    private func authMode(_ credentials: APICredential) -> String {
        if !credentials.bearerToken.isEmpty { return "bearer" }
        if !credentials.apiKey.isEmpty { return "api_key" }
        return "none"
    }

    private static func apiMessage(from data: Data) -> String {
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return ""
        }
        if let message = object["status_message"] as? String {
            return message
        }
        if let errors = object["errors"] as? [String] {
            return errors.joined(separator: "; ")
        }
        return ""
    }

    private func debugLog(endpoint: APIEndpoint, auth: String, status: Int?, bytes: Int, message: String) {
        #if DEBUG
        let statusText = status.map(String.init) ?? "none"
        let safeMessage = message.replacingOccurrences(of: "\n", with: " ")
        Logger(subsystem: "com.lumen.discovery", category: "tmdb").notice(
            "TMDB endpoint=\(endpoint.path, privacy: .public) auth=\(auth, privacy: .public) status=\(statusText, privacy: .public) bytes=\(bytes) message=\(safeMessage, privacy: .public)"
        )
        #endif
    }
}
