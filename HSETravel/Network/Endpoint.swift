import Foundation

/// Abstraction for API endpoints. Encapsulates path, query items, HTTP method, and headers.
struct Endpoint {
    let baseURL: URL
    let path: String
    var queryItems: [URLQueryItem] = []
    var method: String = "GET"
    var headers: [String: String] = [:]

    var url: URL {
        var c = URLComponents(url: path == "" ? baseURL : baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if !queryItems.isEmpty { c.queryItems = queryItems }
        return c.url!
    }
}
