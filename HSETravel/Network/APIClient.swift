import Foundation
import Logging

final class APIClient: APIClientProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func request<T: Decodable>(_ endpoint: Endpoint) async throws -> T {
        let url = endpoint.url
        logger.info("Network request", metadata: ["url": "\(url.absoluteString)"])
        var req = URLRequest(url: url)
        req.httpMethod = endpoint.method
        for (key, value) in endpoint.headers {
            req.setValue(value, forHTTPHeaderField: key)
        }

        do {
            let (data, resp) = try await session.data(for: req)
            guard let http = resp as? HTTPURLResponse else {
                logger.error("Invalid response type")
                throw NetworkError.urlError
            }
            logger.info("Network response", metadata: ["status": "\(http.statusCode)"])
            guard 200 ..< 300 ~= http.statusCode else {
                logger.error("HTTP error", metadata: ["status": "\(http.statusCode)"])
                throw NetworkError.httpError(statusCode: http.statusCode)
            }
            do {
                let decoded = try JSONDecoder().decode(T.self, from: data)
                return decoded
            } catch {
                logger.logError(error, message: "Decoding failed")
                throw NetworkError.decodingError(error)
            }
        } catch {
            if let urlError = error as? URLError {
                switch urlError.code {
                case .notConnectedToInternet, .cannotFindHost, .dnsLookupFailed, .networkConnectionLost:
                    logger.error("Network unreachable or DNS failure", metadata: ["error": "\(urlError)"])
                    throw NetworkError.noInternet
                default:
                    logger.logError(urlError, message: "Network layer failed")
                    throw NetworkError.network(urlError)
                }
            }
            logger.logError(error, message: "Network layer failed")
            throw NetworkError.network(error)
        }
    }
}
