import UIKit

final class CountryCell: UICollectionViewCell {
    static let reuseId = "CountryCell"
    private let flagImageView = UIImageView()
    private let flagFallbackLabel = UILabel()
    private let nameLabel = UILabel()
    private let capitalLabel = UILabel()
    private let populationLabel = UILabel()
    private let favButton = UIButton(type: .system)
    private var representedFlagURL: URL?
    private var isStarred: Bool = false {
        didSet {
            setFavorite(isStarred)
        }
    }

    var onFavorite: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError("init coder not supported") }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let buttonPoint = favButton.convert(point, from: self)
        if favButton.point(inside: buttonPoint, with: event) {
            return favButton
        }
        return super.hitTest(point, with: event)
    }

    private func setup() {
        contentView.backgroundColor = .secondarySystemBackground
        contentView.layer.cornerRadius = 8
        flagImageView.contentMode = .scaleAspectFill
        flagImageView.clipsToBounds = true
        flagImageView.layer.cornerRadius = 6
        flagFallbackLabel.text = "?"
        flagFallbackLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        flagFallbackLabel.textAlignment = .center
        flagFallbackLabel.isHidden = true
        nameLabel.font = .preferredFont(forTextStyle: .headline)
        capitalLabel.font = .preferredFont(forTextStyle: .subheadline)
        populationLabel.font = .preferredFont(forTextStyle: .footnote)

        favButton.setImage(UIImage(systemName: "star"), for: .normal)
        favButton.tintColor = .systemYellow
        favButton.addTarget(self, action: #selector(favTapped), for: .primaryActionTriggered)

        let v = UIStackView(arrangedSubviews: [nameLabel, capitalLabel, populationLabel])
        v.axis = .vertical
        v.spacing = 4
        flagImageView.translatesAutoresizingMaskIntoConstraints = false
        v.translatesAutoresizingMaskIntoConstraints = false
        favButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(flagImageView)
        flagImageView.addSubview(flagFallbackLabel)
        contentView.addSubview(v)
        contentView.addSubview(favButton)
        flagFallbackLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            flagImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            flagImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            flagImageView.widthAnchor.constraint(equalToConstant: 72),
            flagImageView.heightAnchor.constraint(equalToConstant: 48),
            flagFallbackLabel.topAnchor.constraint(equalTo: flagImageView.topAnchor),
            flagFallbackLabel.leadingAnchor.constraint(equalTo: flagImageView.leadingAnchor),
            flagFallbackLabel.trailingAnchor.constraint(equalTo: flagImageView.trailingAnchor),
            flagFallbackLabel.bottomAnchor.constraint(equalTo: flagImageView.bottomAnchor),

            v.leadingAnchor.constraint(equalTo: flagImageView.trailingAnchor, constant: 8),
            v.trailingAnchor.constraint(equalTo: favButton.leadingAnchor, constant: -8),
            v.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),

            favButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favButton.widthAnchor.constraint(equalToConstant: 32),
            favButton.heightAnchor.constraint(equalToConstant: 32),
        ])
    }

    func configure(with country: Country, isFavorite: Bool) {
        nameLabel.text = country.displayName
        capitalLabel.text = "Capital: \(country.capitalName ?? "—")"
        populationLabel.text = "Population: \(country.population.map { String($0) } ?? "—")"
        isStarred = isFavorite
        representedFlagURL = country.flagURL
        setFlagPlaceholder()
        if let url = country.flagURL {
            Task { [weak self] in
                let image = await ImageLoader.shared.loadImage(from: url)
                await MainActor.run {
                    guard self?.representedFlagURL == url else { return }
                    if let image {
                        self?.flagImageView.contentMode = .scaleAspectFill
                        self?.flagImageView.backgroundColor = .clear
                        self?.flagFallbackLabel.isHidden = true
                        self?.flagImageView.image = image
                    } else {
                        self?.setFlagPlaceholder()
                    }
                }
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onFavorite = nil
        representedFlagURL = nil
        setFlagPlaceholder()
        setFavorite(false)
    }

    private func setFlagPlaceholder() {
        flagImageView.contentMode = .scaleAspectFit
        flagImageView.backgroundColor = .tertiarySystemFill
        flagImageView.image = nil
        flagFallbackLabel.isHidden = false
    }

    private func setFavorite(_ isFavorite: Bool) {
        favButton.setImage(UIImage(systemName: isFavorite ? "star.fill" : "star"), for: .normal)
    }

    @objc private func favTapped() {
        onFavorite?()
        isStarred.toggle()
    }
}
