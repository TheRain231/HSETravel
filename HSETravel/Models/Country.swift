import Foundation

nonisolated struct Country: Decodable, Hashable, Sendable {
    struct Names: Decodable, Hashable, Sendable {
        let common: String
        let official: String?
    }

    struct Codes: Decodable, Hashable, Sendable {
        let alpha2: String?
        let alpha3: String?
        let ccn3: String?
        let cioc: String?
        let fifa: String?
        let fips: String?
        let gec: String?

        enum CodingKeys: String, CodingKey {
            case alpha2 = "alpha_2"
            case alpha3 = "alpha_3"
            case ccn3, cioc, fifa, fips, gec
        }
    }

    struct Capital: Decodable, Hashable, Sendable {
        let name: String?
        let coordinates: Coordinates?
        let attributes: CapitalAttributes?

        struct Coordinates: Decodable, Hashable, Sendable {
            let lat: Double?
            let lng: Double?
        }

        struct CapitalAttributes: Decodable, Hashable, Sendable {
            let administrative: Bool?
            let constitutional: Bool?
            let executive: Bool?
            let judicial: Bool?
            let legislative: Bool?
            let primary: Bool?
        }
    }

    struct Flag: Decodable, Hashable, Sendable {
        let description: String?
        let emoji: String?
        let htmlEntity: String?
        let unicode: String?
        let urlPNG: URL?
        let urlSVG: URL?

        enum CodingKeys: String, CodingKey {
            case description, emoji
            case htmlEntity = "html_entity"
            case unicode
            case urlPNG = "url_png"
            case urlSVG = "url_svg"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            description = try container.decodeIfPresent(String.self, forKey: .description)
            emoji = try container.decodeIfPresent(String.self, forKey: .emoji)
            htmlEntity = try container.decodeIfPresent(String.self, forKey: .htmlEntity)
            unicode = try container.decodeIfPresent(String.self, forKey: .unicode)

            if let urlStr = try container.decodeIfPresent(String.self, forKey: .urlPNG), !urlStr.isEmpty {
                urlPNG = URL(string: urlStr)
            } else {
                urlPNG = nil
            }

            if let urlStr = try container.decodeIfPresent(String.self, forKey: .urlSVG), !urlStr.isEmpty {
                urlSVG = URL(string: urlStr)
            } else {
                urlSVG = nil
            }
        }
    }

    struct Area: Decodable, Hashable, Sendable {
        let kilometers: Double?
        let miles: Double?
    }

    struct Language: Decodable, Hashable, Sendable {
        let bcp47: String?
        let iso639_1: String?
        let iso639_2b: String?
        let iso639_2t: String?
        let iso639_3: String?
        let name: String?
        let nativeName: String?

        enum CodingKeys: String, CodingKey {
            case bcp47
            case iso639_1
            case iso639_2b
            case iso639_2t
            case iso639_3
            case name
            case nativeName = "native_name"
        }
    }

    struct Currency: Decodable, Hashable, Sendable {
        let code: String?
        let name: String?
        let symbol: String?
    }

    let names: Names
    let codes: Codes?
    let capitals: [Capital]?
    let population: Int?
    let area: Area?
    let region: String?
    let subregion: String?
    let flag: Flag?
    let languages: [Language]?
    let currencies: [Currency]?

    var capitalName: String? { capitals?.first?.name }
    var displayName: String { names.common }
    var officialName: String? { names.official }
    var codeAlpha3: String? { codes?.alpha3 }
    var languageNames: [String] { languages?.compactMap { $0.name } ?? [] }
    var currencyNames: [String] { currencies?.compactMap { $0.name } ?? [] }
    var areaKilometers: Double? { area?.kilometers }
    var flagURL: URL? { flag?.urlPNG ?? flag?.urlSVG }
}
