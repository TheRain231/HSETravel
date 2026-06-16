import Foundation
import UIKit

final class DIContainer {
    let apiClient: APIClientProtocol
    let countryRepository: CountryRepositoryProtocol
    let openWeatherRepository: OpenWeatherRepositoryProtocol
    let unsplashRepository: UnsplashRepositoryProtocol
    let favoritesRepository: FavoritesRepositoryProtocol

    init(openWeatherKey: String, unsplashKey: String, restCountriesKey: String) {
        apiClient = APIClient()
        countryRepository = CountryRepository(client: apiClient, apiKey: restCountriesKey)
        openWeatherRepository = OpenWeatherRepository(client: apiClient, apiKey: openWeatherKey)
        unsplashRepository = UnsplashRepository(client: apiClient, apiKey: unsplashKey)
        favoritesRepository = FavoritesRepository()
    }
}
