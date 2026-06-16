import Combine
import Foundation

final class FavoritesViewModel {
    @Published private(set) var favorites: [FavoriteCountry] = []
    @Published private(set) var isEmpty: Bool = true

    private let favoritesRepo: FavoritesRepositoryProtocol

    init(favoritesRepo: FavoritesRepositoryProtocol) {
        self.favoritesRepo = favoritesRepo
        load()
    }

    func load() {
        favorites = favoritesRepo.fetchFavorites()
        isEmpty = favorites.isEmpty
    }

    func remove(id: String) {
        do { try favoritesRepo.remove(id: id); load() } catch { print(error) }
    }
}
