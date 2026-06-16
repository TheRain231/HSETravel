import Combine
import UIKit

final class HomeViewController: UIViewController {
    private let viewModel: HomeViewModel
    private var collectionView: UICollectionView!
    private var dataSource: UICollectionViewDiffableDataSource<Int, Country>!
    private var cancellables = Set<AnyCancellable>()
    private let refresh = UIRefreshControl()
    private let activity = UIActivityIndicatorView(style: .large)
    private let paginationView = PaginationControlView()

    var onSelectCountry: ((Country) -> Void)?
    var onAddFavorite: ((Country) -> Void)?

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configurePaginationView()
        configureCollectionView()
        bind()
        viewModel.fetchCountries()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadData()
    }

    private func configureCollectionView() {
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(CountryCell.self, forCellWithReuseIdentifier: CountryCell.reuseId)
        collectionView.refreshControl = refresh
        collectionView.delegate = self
        refresh.addTarget(self, action: #selector(didPull), for: .valueChanged)
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: paginationView.topAnchor, constant: -8),
        ])

        dataSource = UICollectionViewDiffableDataSource<Int, Country>(collectionView: collectionView, cellProvider: { collectionView, indexPath, country in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CountryCell.reuseId, for: indexPath) as! CountryCell
            cell.configure(with: country, isFavorite: self.viewModel.isFavorite(country))
            cell.onFavorite = { [weak self] in self?.onAddFavorite?(country) }
            return cell
        })

        view.addSubview(activity)
        activity.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            activity.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activity.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }

    private func configurePaginationView() {
        paginationView.onPrevious = { [weak self] in self?.viewModel.previousPage() }
        paginationView.onNext = { [weak self] in self?.viewModel.nextPage() }
        view.addSubview(paginationView)

        NSLayoutConstraint.activate([
            paginationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            paginationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            paginationView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
        ])
    }

    private func makeLayout() -> UICollectionViewLayout {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.interGroupSpacing = 8
        section.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        return UICollectionViewCompositionalLayout(section: section)
    }

    @objc private func didPull() { viewModel.refresh() }

    private func bind() {
        viewModel.$countries.receive(on: DispatchQueue.main).sink { [weak self] items in
            self?.refresh.endRefreshing()
            var snap = NSDiffableDataSourceSnapshot<Int, Country>()
            snap.appendSections([0]); snap.appendItems(items)
            self?.dataSource.apply(snap, animatingDifferences: true)
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

        viewModel.$isLoading.receive(on: DispatchQueue.main).sink { [weak self] loading in
            if loading { self?.activity.startAnimating() } else { self?.activity.stopAnimating() }
        }.store(in: &cancellables)

        viewModel.$error.receive(on: DispatchQueue.main).sink { [weak self] error in
            guard let self = self, let error = error else { return }
            let av = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
            av.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(av, animated: true)
        }.store(in: &cancellables)
    }
}

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        onSelectCountry?(item)
    }
}
