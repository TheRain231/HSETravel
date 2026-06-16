import Foundation

struct WeatherResponse: Decodable {
    let weather: [Weather]
    let main: Main
    let wind: Wind

    struct Weather: Decodable { let description: String; let icon: String }
    struct Main: Decodable { let temp: Double; let humidity: Int }
    struct Wind: Decodable { let speed: Double }
}
