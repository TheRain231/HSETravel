import Logging

let logger = Logger(label: "com.hsetravel.app")

extension Logger {
    func logError(_ error: Error, message: String) {
        self.error("\(message)", metadata: ["error": "\(error)"])
    }
}
