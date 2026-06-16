import Foundation
import Logging

protocol OpenWeatherRepositoryProtocol {
    func fetchWeather(forCity city: String, countryCode: String?) async throws -> WeatherResponse
}

final class OpenWeatherRepository: OpenWeatherRepositoryProtocol {
    private let client: APIClientProtocol
    private let base = URL(string: "https://api.openweathermap.org/data/2.5")!
    private let apiKey: String

    init(client: APIClientProtocol, apiKey: String) {
        self.client = client
        self.apiKey = apiKey
    }

    func fetchWeather(forCity city: String, countryCode: String? = nil) async throws -> WeatherResponse {
        var q = city
        if let c = countryCode { q += ",\(c)" }
        logger.info("OpenWeatherRepository: fetch weather", metadata: ["city": "\(city)"])
        let ep = Endpoint(baseURL: base, path: "weather", queryItems: [URLQueryItem(name: "q", value: q), URLQueryItem(name: "appid", value: apiKey), URLQueryItem(name: "units", value: "metric")])
        return try await client.request(ep)
    }
}
