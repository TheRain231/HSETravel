import UIKit

final class ImageLoader {
    static let shared = ImageLoader()
    private let cache = NSCache<NSURL, UIImage>()
    private let session: URLSession

    init(session: URLSession = .shared) { self.session = session }

    func loadImage(from url: URL) async -> UIImage? {
        if let img = cache.object(forKey: url as NSURL) { return img }
        do {
            let (data, _) = try await session.data(from: url)
            if let image = UIImage(data: data) {
                cache.setObject(image, forKey: url as NSURL)
                return image
            }
        } catch { return nil }
        return nil
    }
}
