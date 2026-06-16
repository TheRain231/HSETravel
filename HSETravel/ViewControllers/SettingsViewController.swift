import UIKit

final class SettingsViewController: UIViewController {
    private let viewModel: SettingsViewModel
    private let savedCountLabel = UILabel()

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        title = "Settings"
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateProfileStats()
    }

    private func setup() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let avatar = UIImageView(image: UIImage(systemName: "person.crop.circle.fill"))
        avatar.tintColor = .systemBlue
        avatar.contentMode = .scaleAspectFit
        avatar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatar.heightAnchor.constraint(equalToConstant: 72),
        ])

        let titleLabel = UILabel()
        titleLabel.text = "Travel Profile"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.textAlignment = .center

        savedCountLabel.font = .preferredFont(forTextStyle: .body)
        savedCountLabel.textColor = .secondaryLabel
        savedCountLabel.textAlignment = .center

        let versionLabel = UILabel()
        versionLabel.text = "Version: \(viewModel.appVersion)"
        versionLabel.textColor = .secondaryLabel
        versionLabel.font = .preferredFont(forTextStyle: .footnote)
        versionLabel.textAlignment = .center

        let btn = UIButton(type: .system)
        btn.setTitle("Clear Favorites", for: .normal)
        btn.setImage(UIImage(systemName: "trash"), for: .normal)
        btn.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        btn.tintColor = .systemRed

        [avatar, titleLabel, savedCountLabel, versionLabel, btn].forEach { stack.addArrangedSubview($0) }

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])

        updateProfileStats()
    }

    private func updateProfileStats() {
        let count = viewModel.favoriteCount
        savedCountLabel.text = "Saved countries: \(count)"
    }

    @objc private func clearTapped() {
        viewModel.clearFavorites()
        updateProfileStats()
        let av = UIAlertController(title: "Cleared", message: "Favorites cleared.", preferredStyle: .alert)
        av.addAction(UIAlertAction(title: "OK", style: .default))
        present(av, animated: true)
    }
}
