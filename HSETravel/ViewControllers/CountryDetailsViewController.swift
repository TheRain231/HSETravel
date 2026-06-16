import Combine
import UIKit

final class CountryDetailsViewController: UIViewController {
    private let viewModel: CountryDetailsViewModel
    private var cancellables = Set<AnyCancellable>()
    var onToggleFavorite: ((Country, Bool) -> Bool)?
    var isFavorite = false {
        didSet {
            updateFavoriteButton()
        }
    }

    private let scroll = UIScrollView()
    private let content = UIStackView()
    private let flagImage = UIImageView()
    private let flagFallbackLabel = UILabel()
    private let titleLabel = UILabel()
    private let capitalLabel = UILabel()

    private let infoLabel = UILabel()
    private let weatherLabel = UILabel()
    private var gallery: UICollectionView!

    private var favoriteButton: UIBarButtonItem?
    private var representedFlagURL: URL?

    init(viewModel: CountryDetailsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupViews()
        setupFavoriteButton()
        bind()
    }

    private func setupViews() {
        scroll.translatesAutoresizingMaskIntoConstraints = false
        content.axis = .vertical
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(content)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 12),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -12),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        ])

        flagImage.contentMode = .scaleAspectFill
        flagImage.clipsToBounds = true
        flagImage.layer.cornerRadius = 8
        flagImage.heightAnchor.constraint(equalToConstant: 180).isActive = true
        flagImage.backgroundColor = .tertiarySystemFill
        flagFallbackLabel.text = "🏳️?"
        flagFallbackLabel.font = .systemFont(ofSize: 56, weight: .semibold)
        flagFallbackLabel.textAlignment = .center
        flagFallbackLabel.translatesAutoresizingMaskIntoConstraints = false
        flagImage.addSubview(flagFallbackLabel)
        NSLayoutConstraint.activate([
            flagFallbackLabel.topAnchor.constraint(equalTo: flagImage.topAnchor),
            flagFallbackLabel.leadingAnchor.constraint(equalTo: flagImage.leadingAnchor),
            flagFallbackLabel.trailingAnchor.constraint(equalTo: flagImage.trailingAnchor),
            flagFallbackLabel.bottomAnchor.constraint(equalTo: flagImage.bottomAnchor),
        ])

        titleLabel.font = .preferredFont(forTextStyle: .largeTitle)
        titleLabel.numberOfLines = 0
        capitalLabel.font = .preferredFont(forTextStyle: .headline)

        infoLabel.numberOfLines = 0
        infoLabel.font = .preferredFont(forTextStyle: .body)
        weatherLabel.numberOfLines = 0
        weatherLabel.font = .preferredFont(forTextStyle: .body)
        weatherLabel.textColor = .secondaryLabel

        // Sections with headers
        let headerFont = UIFont.preferredFont(forTextStyle: .headline)

        let infoHeader = UILabel()
        infoHeader.text = "Country Information"
        infoHeader.font = headerFont

        let weatherHeader = UILabel()
        weatherHeader.text = "Weather"
        weatherHeader.font = headerFont

        let galleryHeader = UILabel()
        galleryHeader.text = "Gallery"
        galleryHeader.font = headerFont

        content.addArrangedSubview(flagImage)
        content.addArrangedSubview(titleLabel)
        content.addArrangedSubview(capitalLabel)
        content.addArrangedSubview(infoHeader)
        content.addArrangedSubview(infoLabel)
        content.addArrangedSubview(weatherHeader)
        content.addArrangedSubview(weatherLabel)
        content.addArrangedSubview(galleryHeader)

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 100)
        layout.minimumLineSpacing = 8
        gallery = UICollectionView(frame: .zero, collectionViewLayout: layout)
        gallery.heightAnchor.constraint(equalToConstant: 110).isActive = true
        gallery.showsHorizontalScrollIndicator = false
        gallery.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "imgCell")
        gallery.dataSource = self
        content.addArrangedSubview(gallery)
    }

    private func setupFavoriteButton() {
        favoriteButton = UIBarButtonItem(image: UIImage(systemName: "star"), style: .plain, target: self, action: #selector(favoriteTapped))
        navigationItem.rightBarButtonItem = favoriteButton
        updateFavoriteButton()
    }

    @objc private func favoriteTapped() {
        let newState = onToggleFavorite?(viewModel.country, isFavorite) ?? false
        isFavorite = newState
//        let toastTitle = newState ? "Added to Favorites" : "Removed from Favorites"
//        let toast = UIAlertController(title: toastTitle, message: nil, preferredStyle: .alert)
//        present(toast, animated: true)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//            toast.dismiss(animated: true)
//        }
    }

    private func updateFavoriteButton() {
        favoriteButton?.image = UIImage(systemName: isFavorite ? "star.fill" : "star")
    }

    private func bind() {
        viewModel.$country.receive(on: DispatchQueue.main).sink { [weak self] c in
            self?.titleLabel.text = c.displayName
            self?.capitalLabel.text = "Capital: \(c.capitalName ?? "—")"

            let langText = c.languageNames.isEmpty ? "—" : c.languageNames.joined(separator: ", ")
            let currText = c.currencyNames.isEmpty ? "—" : c.currencyNames.joined(separator: ", ")
            let areaText = c.areaKilometers.map { String(format: "%.0f", $0) } ?? "—"
            let popText = c.population.map { String($0) } ?? "—"

            self?.infoLabel.text = "Population: \(popText)\nArea: \(areaText) km²\nRegion: \(c.region ?? "—")\nSubregion: \(c.subregion ?? "—")\nLanguages: \(langText)\nCurrencies: \(currText)"
            self?.setFlag(from: c.flagURL)
        }.store(in: &cancellables)

        viewModel.$weather.receive(on: DispatchQueue.main).sink { [weak self] w in
            guard let w = w else { self?.weatherLabel.text = "No weather data"; return }
            let temp = String(format: "%.1f", w.main.temp)
            self?.weatherLabel.text = "Temperature: \(temp)°C\nDescription: \(w.weather.first?.description.capitalized ?? "—")\nHumidity: \(w.main.humidity)%\nWind Speed: \(w.wind.speed) m/s"
        }.store(in: &cancellables)

        viewModel.$photos.receive(on: DispatchQueue.main).sink { [weak self] _ in self?.gallery.reloadData() }.store(in: &cancellables)
    }

    private func setFlag(from url: URL?) {
        representedFlagURL = url
        setFlagPlaceholder()
        guard let url else { return }

        Task { [weak self] in
            let image = await ImageLoader.shared.loadImage(from: url)
            await MainActor.run {
                guard self?.representedFlagURL == url else { return }
                if let image {
                    self?.flagImage.contentMode = .scaleAspectFill
                    self?.flagImage.backgroundColor = .clear
                    self?.flagFallbackLabel.isHidden = true
                    self?.flagImage.image = image
                } else {
                    self?.setFlagPlaceholder()
                }
            }
        }
    }

    private func setFlagPlaceholder() {
        flagImage.contentMode = .scaleAspectFit
        flagImage.backgroundColor = .tertiarySystemFill
        flagImage.image = nil
        flagFallbackLabel.isHidden = false
    }
}

extension CountryDetailsViewController: UICollectionViewDataSource {
    func collectionView(_: UICollectionView, numberOfItemsInSection _: Int) -> Int { viewModel.photos.count }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imgCell", for: indexPath)
        cell.contentView.subviews.forEach { $0.removeFromSuperview() }

        let imgView = UIImageView(frame: cell.contentView.bounds)
        imgView.contentMode = .scaleAspectFill
        imgView.clipsToBounds = true
        imgView.layer.cornerRadius = 6

        let photo = viewModel.photos[indexPath.item]
        imgView.setImage(from: photo.urls.small)
        cell.contentView.addSubview(imgView)
        return cell
    }
}
