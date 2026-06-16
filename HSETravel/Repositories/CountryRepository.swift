import Foundation
import Logging

protocol CountryRepositoryProtocol {
    func fetchCountries(page: Int, limit: Int) async throws -> CountryPage
    func searchCountries(by name: String, page: Int, limit: Int) async throws -> CountryPage
}

struct CountryPage {
    let countries: [Country]
    let meta: CountryListMeta
}

private struct CountryListResponse: Decodable {
    let data: CountryListData
}

private struct CountryListData: Decodable {
    let objects: [Country]
    let meta: CountryListMeta
}

struct CountryListMeta: Decodable {
    let total: Int
    let count: Int
    let limit: Int
    let offset: Int
    let more: Bool?
}

final class CountryRepository: CountryRepositoryProtocol {
    private let client: APIClientProtocol
    private let base = URL(string: "https://api.restcountries.com/countries/v5")!
    private let apiKey: String

    init(client: APIClientProtocol, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    func fetchCountries(page: Int, limit: Int) async throws -> CountryPage {
        logger.info("CountryRepository: fetch paged countries", metadata: ["page": "\(page)", "limit": "\(limit)"])
        let offset = page * limit
        var queryItems = [URLQueryItem(name: "limit", value: "\(limit)")]
        if offset > 0 { queryItems.append(URLQueryItem(name: "offset", value: "\(offset)")) }
        var ep = Endpoint(baseURL: base, path: "", queryItems: queryItems)
        ep.headers = ["Authorization": "Bearer \(apiKey)"]
        let response: CountryListResponse = try await client.request(ep)
        return CountryPage(countries: response.data.objects, meta: response.data.meta)
    }

    func searchCountries(by name: String, page: Int = 0, limit: Int = 20) async throws -> CountryPage {
        logger.info("CountryRepository: search countries", metadata: ["query": "\(name)", "page": "\(page)", "limit": "\(limit)"])
        let offset = page * limit
        var queryItems = [
            URLQueryItem(name: "q", value: name),
            URLQueryItem(name: "limit", value: "\(limit)"),
        ]
        if offset > 0 { queryItems.append(URLQueryItem(name: "offset", value: "\(offset)")) }
        var ep = Endpoint(baseURL: base, path: "", queryItems: queryItems)
        ep.headers = ["Authorization": "Bearer \(apiKey)"]
        let response: CountryListResponse = try await client.request(ep)
        return CountryPage(countries: response.data.objects, meta: response.data.meta)
    }
}
