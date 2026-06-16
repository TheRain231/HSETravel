import Foundation

struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Decodable, Hashable {
    let id: String
    let urls: URLS

    struct URLS: Hashable {
        let small: URL?
        let thumb: URL?
    }

    enum CodingKeys: String, CodingKey {
        case id, urls
    }

    enum URLSCodingKeys: String, CodingKey {
        case small, thumb
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)

        let urlsContainer = try container.nestedContainer(keyedBy: URLSCodingKeys.self, forKey: .urls)
        let smallStr = try urlsContainer.decodeIfPresent(String.self, forKey: .small)
        let thumbStr = try urlsContainer.decodeIfPresent(String.self, forKey: .thumb)

        urls = URLS(
            small: smallStr.flatMap { $0.isEmpty ? nil : URL(string: $0) },
            thumb: thumbStr.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        )
    }
}
