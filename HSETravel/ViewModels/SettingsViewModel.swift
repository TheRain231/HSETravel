import Foundation

final class SettingsViewModel {
    private let favoritesRepo: FavoritesRepositoryProtocol

    init(favoritesRepo: FavoritesRepositoryProtocol) { self.favoritesRepo = favoritesRepo }

    func clearFavorites() {
        do { try favoritesRepo.clear() } catch { print(error) }
    }

    var favoriteCount: Int {
        favoritesRepo.fetchFavorites().count
    }

    var appVersion: String {
        let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(ver) (\(build))"
    }
}
