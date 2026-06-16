import Combine
import UIKit

final class SearchViewController: UIViewController {
    private let viewModel: SearchViewModel
    private var tableView = UITableView()
    private var cancellables = Set<AnyCancellable>()
    private let searchController = UISearchController(searchResultsController: nil)
    private let emptyLabel = UILabel()
    private let paginationView = PaginationControlView()
    var onSelectCountry: ((Country) -> Void)?

    init(viewModel: SearchViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.searchController = searchController
        title = "Search"
        setupPaginationView()
        setupTable()
        bind()
        setupSearchBinding()
    }

    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        emptyLabel.text = "Text search across every searchable property.\nOn every language."
        emptyLabel.textColor = .secondaryLabel
        emptyLabel.font = .preferredFont(forTextStyle: .body)
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        tableView.backgroundView = emptyLabel
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: paginationView.topAnchor, constant: -8),
        ])
    }

    private func setupPaginationView() {
        paginationView.onPrevious = { [weak self] in self?.viewModel.previousPage() }
        paginationView.onNext = { [weak self] in self?.viewModel.nextPage() }
        view.addSubview(paginationView)
        NSLayoutConstraint.activate([
            paginationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            paginationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            paginationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    private func bind() {
        viewModel.$results.receive(on: DispatchQueue.main).sink { [weak self] results in
            self?.tableView.reloadData()
            self?.emptyLabel.isHidden = !results.isEmpty
        }.store(in: &cancellables)

        viewModel.$currentPage
            .combineLatest(viewModel.$totalPages, viewModel.$canGoPrevious, viewModel.$canGoNext)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] current, total, canGoPrevious, canGoNext in
                self?.paginationView.configure(
                    currentPage: current,
                    totalPages: total,
                    canGoPrevious: canGoPrevious,
                    canGoNext: canGoNext
                )
            }.store(in: &cancellables)
    }

    private func setupSearchBinding() {
        let publisher = NotificationCenter.default.publisher(for: UISearchTextField.textDidChangeNotification, object: searchController.searchBar.searchTextField)
            .compactMap { ($0.object as? UISearchTextField)?.text }
            .eraseToAnyPublisher()
        viewModel.searchPublisher(publisher)
    }
}

extension SearchViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int { viewModel.results.count }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let c = viewModel.results[indexPath.row]
        cell.textLabel?.text = c.displayName
        cell.detailTextLabel?.text = c.capitalName
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country = viewModel.results[indexPath.row]
        onSelectCountry?(country)
    }
}
