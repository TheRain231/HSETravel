import UIKit

final class PaginationControlView: UIView {
    private let effectView: UIVisualEffectView
    private let stack = UIStackView()
    private let previousButton = UIButton(type: .system)
    private let nextButton = UIButton(type: .system)
    private let pageLabel = UILabel()

    var onPrevious: (() -> Void)?
    var onNext: (() -> Void)?

    override init(frame: CGRect) {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = true
            effect.tintColor = UIColor.systemBackground.withAlphaComponent(0.18)
            effectView = UIVisualEffectView(effect: effect)
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        }
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        if #available(iOS 26.0, *) {
            let effect = UIGlassEffect(style: .regular)
            effect.isInteractive = true
            effect.tintColor = UIColor.systemBackground.withAlphaComponent(0.18)
            effectView = UIVisualEffectView(effect: effect)
        } else {
            effectView = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        }
        super.init(coder: coder)
        setup()
    }

    func configure(currentPage: Int, totalPages: Int, canGoPrevious: Bool, canGoNext: Bool) {
        pageLabel.text = "Page \(currentPage + 1) of \(totalPages)"
        previousButton.isEnabled = canGoPrevious
        nextButton.isEnabled = canGoNext
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        clipsToBounds = true
        layer.cornerRadius = 22
        layer.cornerCurve = .continuous

        effectView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(effectView)
        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: topAnchor),
            effectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: trailingAnchor),
            effectView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        stack.distribution = .equalCentering
        stack.translatesAutoresizingMaskIntoConstraints = false
        effectView.contentView.addSubview(stack)

        pageLabel.font = .preferredFont(forTextStyle: .subheadline)
        pageLabel.textAlignment = .center
        pageLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        configureButton(previousButton, systemImageName: "chevron.left", action: #selector(previousTapped))
        configureButton(nextButton, systemImageName: "chevron.right", action: #selector(nextTapped))

        stack.addArrangedSubview(previousButton)
        stack.addArrangedSubview(pageLabel)
        stack.addArrangedSubview(nextButton)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            stack.topAnchor.constraint(equalTo: effectView.contentView.topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: effectView.contentView.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: effectView.contentView.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: effectView.contentView.bottomAnchor, constant: -4),
            previousButton.widthAnchor.constraint(equalToConstant: 40),
            nextButton.widthAnchor.constraint(equalToConstant: 40),
        ])

        configure(currentPage: 0, totalPages: 1, canGoPrevious: false, canGoNext: false)
    }

    private func configureButton(_ button: UIButton, systemImageName: String, action: Selector) {
        if #available(iOS 26.0, *) {
            var config = UIButton.Configuration.glass()
            config.image = UIImage(systemName: systemImageName)
            button.configuration = config
        } else {
            button.setImage(UIImage(systemName: systemImageName), for: .normal)
        }
        button.addTarget(self, action: action, for: .primaryActionTriggered)
    }

    @objc private func previousTapped() {
        onPrevious?()
    }

    @objc private func nextTapped() {
        onNext?()
    }
}
