import UIKit

extension UIImageView {
    func setImage(from url: URL?) {
        guard let url = url else { image = nil; return }
        Task { [weak self] in
            let img = await ImageLoader.shared.loadImage(from: url)
            await MainActor.run { self?.image = img }
        }
    }
}
