import Combine
import Foundation
import Logging

final class SearchViewModel {
    @Published private(set) var results: [Country] = []
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: Error?
    @Published private(set) var currentPage: Int = 0
    @Published private(set) var totalPages: Int = 1
    @Published private(set) var canGoPrevious: Bool = false
    @Published private(set) var canGoNext: Bool = false

    private let countryRepo: CountryRepositoryProtocol
    private var searchCancellable: AnyCancellable?
    private var currentQuery = ""
    private let pageSize = 10

    init(countryRepo: CountryRepositoryProtocol) {
        self.countryRepo = countryRepo
    }

    func searchPublisher(_ publisher: AnyPublisher<String, Never>) {
        searchCancellable = publisher
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] term in
                guard let self = self else { return }
                if term.isEmpty {
                    self.currentQuery = ""
                    self.results = []
                    self.currentPage = 0
                    self.totalPages = 1
                    self.canGoPrevious = false
                    self.canGoNext = false
                    return
                }
                self.currentQuery = term
                self.search(page: 0)
            }
    }

    func nextPage() {
        guard canGoNext else { return }
        search(page: currentPage + 1)
    }

    func previousPage() {
        guard canGoPrevious else { return }
        search(page: currentPage - 1)
    }

    private func search(page: Int) {
        guard !currentQuery.isEmpty else { return }
        logger.info("Searching countries", metadata: ["query": "\(currentQuery)", "page": "\(page)"])
        Task {
            await MainActor.run { self.isLoading = true; self.error = nil }
            do {
                let pageData = try await self.countryRepo.searchCountries(by: self.currentQuery, page: page, limit: self.pageSize)
                await MainActor.run {
                    self.results = pageData.countries
                    self.currentPage = page
                    self.totalPages = max(1, Int(ceil(Double(pageData.meta.total) / Double(pageData.meta.limit))))
                    self.canGoPrevious = page > 0
                    self.canGoNext = pageData.meta.more == true || page < self.totalPages - 1
                    self.isLoading = false
                }
                logger.info("Search completed", metadata: ["count": "\(pageData.countries.count)", "page": "\(page)"])
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
                logger.logError(error, message: "Search failed")
            }
        }
    }
}
