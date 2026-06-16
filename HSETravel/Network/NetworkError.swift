import Foundation

enum NetworkError: Error {
    case urlError
    case httpError(statusCode: Int)
    case decodingError(Error)
    case network(Error)
    case noInternet
}

extension NetworkError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .urlError:
            return "Invalid response from server."
        case let .httpError(statusCode):
            return "Server returned status code \(statusCode)."
        case .decodingError:
            return "Failed to decode server data."
        case .network:
            return "Network request failed."
        case .noInternet:
            return "No internet connection or DNS lookup failed."
        }
    }
}
