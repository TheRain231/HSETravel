import Combine
import Foundation
import Logging

final class HomeViewModel {
    @Published private(set) var countries: [Country] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var currentPage: Int = 0
    @Published private(set) var totalPages: Int = 1
    @Published private(set) var canGoPrevious: Bool = false
    @Published private(set) var canGoNext: Bool = false

    private let countryRepo: CountryRepositoryProtocol
    private let favoritesRepo: FavoritesRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 10

    init(countryRepo: CountryRepositoryProtocol, favoritesRepo: FavoritesRepositoryProtocol) {
        self.countryRepo = countryRepo
        self.favoritesRepo = favoritesRepo
    }

    func fetchCountries(page: Int = 0) {
        logger.info("Fetching countries", metadata: ["page": "\(page)"])
        Task {
            await MainActor.run { self.isLoading = true; self.error = nil }
            do {
                let pageData = try await countryRepo.fetchCountries(page: page, limit: pageSize)
                let sorted = pageData.countries.sorted { $0.displayName < $1.displayName }
                await MainActor.run {
                    self.countries = sorted
                    self.currentPage = page
                    self.totalPages = max(1, Int(ceil(Double(pageData.meta.total) / Double(pageData.meta.limit))))
                    self.canGoPrevious = page > 0
                    self.canGoNext = pageData.meta.more == true || page < self.totalPages - 1
                    self.isLoading = false
                }
                logger.info("Fetched countries", metadata: ["count": "\(sorted.count)", "page": "\(page)"])
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
                logger.logError(error, message: "Failed to fetch countries")
            }
        }
    }

    func refresh() { fetchCountries(page: currentPage) }
    func nextPage() { guard canGoNext else { return }; fetchCountries(page: currentPage + 1) }
    func previousPage() { guard canGoPrevious else { return }; fetchCountries(page: currentPage - 1) }

    func isFavorite(_ country: Country) -> Bool {
        favoritesRepo.contains(country: country)
    }
}
