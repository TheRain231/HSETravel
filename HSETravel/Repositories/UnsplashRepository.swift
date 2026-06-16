import Foundation
import Logging

protocol UnsplashRepositoryProtocol {
    func searchPhotos(for query: String, perPage: Int) async throws -> [UnsplashPhoto]
}

final class UnsplashRepository: UnsplashRepositoryProtocol {
    private let client: APIClientProtocol
    private let base = URL(string: "https://api.unsplash.com")!
    private let apiKey: String

    init(client: APIClientProtocol, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    func searchPhotos(for query: String, perPage: Int = 10) async throws -> [UnsplashPhoto] {
        logger.info("UnsplashRepository: search photos", metadata: ["query": "\(query)", "perPage": "\(perPage)"])
        let ep = Endpoint(baseURL: base, path: "search/photos", queryItems: [URLQueryItem(name: "query", value: query), URLQueryItem(name: "per_page", value: String(perPage)), URLQueryItem(name: "client_id", value: apiKey)])
        let res: UnsplashSearchResponse = try await client.request(ep)
        logger.info("UnsplashRepository: search completed", metadata: ["count": "\(res.results.count)"])
        return res.results
    }
}
