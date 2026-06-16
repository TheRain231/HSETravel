import Logging
import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private let container: DIContainer

    init(window: UIWindow, container: DIContainer) {
        self.window = window
        self.container = container
    }

    func start() {
        let tab = UITabBarController()

        let homeVM = HomeViewModel(countryRepo: container.countryRepository, favoritesRepo: container.favoritesRepository)
        let homeVC = HomeViewController(viewModel: homeVM)
        homeVC.title = "Countries"
        let homeNav = UINavigationController(rootViewController: homeVC)
        homeNav.tabBarItem = UITabBarItem(title: "Home", image: UIImage(systemName: "house"), tag: 0)

        // Selection: push details and provide DI to details view model
        homeVC.onSelectCountry = { [weak homeNav, weak self] country in
            guard let self = self, let nav = homeNav else { return }
            self.showDetails(for: country, in: nav)
        }

        // Favorite callback
        homeVC.onAddFavorite = { [weak self] country in
            guard let self = self else { return }
            do {
                if self.container.favoritesRepository.contains(country: country) {
                    guard let id = country.favoriteID else { return }
                    try self.container.favoritesRepository.remove(id: id)
                } else {
                    try self.container.favoritesRepository.add(country: country)
                }
            } catch {
                logger.logError(error, message: "Fav error: \(error)")
            }
        }

        let searchVM = SearchViewModel(countryRepo: container.countryRepository)
        let searchVC = SearchViewController(viewModel: searchVM)
        let searchNav = UINavigationController(rootViewController: searchVC)
        searchNav.tabBarItem = UITabBarItem(title: "Search", image: UIImage(systemName: "magnifyingglass"), tag: 1)

        searchVC.onSelectCountry = { [weak searchNav, weak self] country in
            guard let self = self, let nav = searchNav else { return }
            self.showDetails(for: country, in: nav)
        }

        let favVM = FavoritesViewModel(favoritesRepo: container.favoritesRepository)
        let favVC = FavoritesViewController(viewModel: favVM)
        let favNav = UINavigationController(rootViewController: favVC)
        favNav.tabBarItem = UITabBarItem(title: "Favorites", image: UIImage(systemName: "star"), tag: 2)

        favVC.onSelectFavoriteCountry = { [weak favNav, weak self] favorite in
            guard let self = self, let nav = favNav else { return }
            Task {
                do {
                    let query = favorite.name ?? favorite.id
                    let countries = try await self.container.countryRepository.searchCountries(by: query, page: 1, limit: 5).countries
                    guard let country = countries.first(where: { $0.codeAlpha3 == favorite.id }) ?? countries.first else { return }
                    await MainActor.run {
                        self.showDetails(for: country, in: nav)
                    }
                } catch {
                    logger.logError(error, message: "Failed to load favorite country")
                }
            }
        }

        let settingsVM = SettingsViewModel(favoritesRepo: container.favoritesRepository)
        let settingsVC = SettingsViewController(viewModel: settingsVM)
        let settingsNav = UINavigationController(rootViewController: settingsVC)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gearshape"), tag: 3)

        tab.viewControllers = [homeNav, searchNav, favNav, settingsNav]
        window.rootViewController = tab
        window.makeKeyAndVisible()
    }

    private func showDetails(for country: Country, in nav: UINavigationController) {
        let detailsVM = CountryDetailsViewModel(
            country: country,
            weatherRepo: container.openWeatherRepository,
            photosRepo: container.unsplashRepository
        )
        let detailsVC = CountryDetailsViewController(viewModel: detailsVM)
        detailsVC.title = country.displayName
        detailsVC.isFavorite = container.favoritesRepository.contains(country: country)
        detailsVC.onToggleFavorite = { [weak self] country, isFavorite in
            guard let self = self else { return isFavorite }
            do {
                if isFavorite {
                    guard let id = country.favoriteID else { return isFavorite }
                    try self.container.favoritesRepository.remove(id: id)
                    logger.info("Removed from favorites from details")
                    return false
                } else {
                    try self.container.favoritesRepository.add(country: country)
                    logger.info("Added to favorites from details")
                    return true
                }
            } catch {
                logger.logError(error, message: "Failed to toggle favorite")
                return isFavorite
            }
        }
        detailsVM.loadSupplementaryData()
        nav.pushViewController(detailsVC, animated: true)
    }
}
