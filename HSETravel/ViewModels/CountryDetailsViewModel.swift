import Combine
import Foundation
import Logging

final class CountryDetailsViewModel {
    @Published private(set) var country: Country
    @Published private(set) var weather: WeatherResponse?
    @Published private(set) var photos: [UnsplashPhoto] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?

    private let weatherRepo: OpenWeatherRepositoryProtocol
    private let photosRepo: UnsplashRepositoryProtocol

    init(country: Country, weatherRepo: OpenWeatherRepositoryProtocol, photosRepo: UnsplashRepositoryProtocol) {
        self.country = country
        self.weatherRepo = weatherRepo
        self.photosRepo = photosRepo
    }

    func loadSupplementaryData() {
        logger.info("Loading supplementary details", metadata: ["country": "\(country.displayName)"])
        Task {
            await MainActor.run { self.isLoading = true; self.error = nil }
            do {
                let country = self.country
                async let w = loadWeather(for: country)
                async let p = photosRepo.searchPhotos(for: country.displayName, perPage: 10)

                let (weatherRes, photosRes) = try await (w, p)
                await MainActor.run {
                    self.weather = weatherRes
                    self.photos = photosRes
                    self.isLoading = false
                }
                logger.info("Supplementary details loaded", metadata: ["country": "\(country.displayName)", "photos": "\(photosRes.count)"])
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
                logger.logError(error, message: "Failed to load details")
            }
        }
    }

    private func loadWeather(for country: Country) async throws -> WeatherResponse? {
        guard let capital = country.capitalName else { return nil }
        return try await weatherRepo.fetchWeather(forCity: capital, countryCode: country.codes?.alpha2)
    }
}
