import Foundation

final class AppConfiguration {
    static let shared = AppConfiguration()

    let openWeatherAPIKey: String
    let unsplashAPIKey: String
    let restCountriesAPIKey: String

    private init(envFileName: String = ".env") {
        let values = Self.loadEnvironmentValues(from: envFileName)
        openWeatherAPIKey = values["OPENWEATHER_API_KEY"] ?? Self.missingKey("OPENWEATHER_API_KEY")
        unsplashAPIKey = values["UNSPLASH_API_KEY"] ?? Self.missingKey("UNSPLASH_API_KEY")
        restCountriesAPIKey = values["RESTCOUNTRIES_API_KEY"] ?? Self.missingKey("RESTCOUNTRIES_API_KEY")
    }

    private static func loadEnvironmentValues(from fileName: String) -> [String: String] {
        if let bundleURL = Bundle.main.url(forResource: fileName, withExtension: nil),
           let contents = try? String(contentsOf: bundleURL) {
            return parseEnv(contents)
        }

        let candidateURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(fileName)
        if FileManager.default.fileExists(atPath: candidateURL.path),
           let contents = try? String(contentsOf: candidateURL) {
            return parseEnv(contents)
        }

        let systemValues = ProcessInfo.processInfo.environment
        return systemValues.filter { ["OPENWEATHER_API_KEY", "UNSPLASH_API_KEY", "RESTCOUNTRIES_API_KEY"].contains($0.key) }
    }

    private static func parseEnv(_ contents: String) -> [String: String] {
        var result = [String: String]()

        for rawLine in contents.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }
            let components = line.split(separator: "=", maxSplits: 1).map { String($0).trimmingCharacters(in: .whitespaces) }
            guard components.count == 2 else { continue }
            let key = components[0]
            let value = components[1].trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
            result[key] = value
        }

        return result
    }

    private static func missingKey(_ name: String) -> String {
        let message = "AppConfiguration: missing required key '\(name)'. Add it to '.env' and include the file in app resources."
        assertionFailure(message)
        return ""
    }
}
