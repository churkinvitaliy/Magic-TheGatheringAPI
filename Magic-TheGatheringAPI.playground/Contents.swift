import Foundation

let nameQueryItem = "name"

struct Profile: Codable {
    let cards: [Card]?
}

struct Card: Codable {
    let name, manaCost: String?
    let type: String?
    let cardSet, setName, text: String?

    enum CodingKeys: String, CodingKey {
        case name, manaCost, type
        case cardSet = "set"
        case setName, text
    }
}

enum NetworkError: Error {
    case badRequest
    case forbidden
    case notFound
    case internalServerError
    case serviceUnavailable
    case unexpected(code: Int)
}

func createURL(queryItems: [URLQueryItem]? = nil) -> URL? {
    var components = URLComponents()
    components.scheme = "https"
    components.host = "api.magicthegathering.io"
    components.path = "/v1/cards"
    components.queryItems = queryItems
    return components.url
}

func createRequest(url: URL?) -> URLRequest? {
    guard let url = url else { return nil }
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    return request
}

func getData(request: URLRequest?, completion: @escaping (Result<Profile, NetworkError>) -> Void) {
    guard let request = request else { return }
    let session = URLSession.shared

    session.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Network Error: \(error.localizedDescription)")
            return
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            print("Unexpected response format")
            return
        }

        switch httpResponse.statusCode {
        case 200:
            if let data = data {
                do {
                    let profile = try JSONDecoder().decode(Profile.self, from: data)
                    completion(.success(profile))
                } catch {
                    print("Error decoding JSON: \(error)")
                    completion(.failure(.unexpected(code: httpResponse.statusCode)))
                }
            } else {
                print("No data received")
                completion(.failure(.unexpected(code: httpResponse.statusCode)))
            }
        case 400:
            completion(.failure(.badRequest))
        case 403:
            completion(.failure(.forbidden))
        case 404:
            completion(.failure(.notFound))
        case 500:
            completion(.failure(.internalServerError))
        case 503:
            completion(.failure(.serviceUnavailable))
        default:
            completion(.failure(.unexpected(code: httpResponse.statusCode)))
        }
    }.resume()
}

func printCardInfo(_ card: Card) {
    print(
        """
        \nCard Name: \(card.name ?? "Unknown")
        Type: \(card.type ?? "Unknown")
        Mana Cost: \(card.manaCost ?? "Unknown")
        Set: \(card.cardSet ?? "Unknown")
        Set Name: \(card.setName ?? "Unknown")
        Text: \(card.text ?? "Unknown")
        ------------------------------------------
        """
    )
}

let nameOpt = "Opt"
let nameBlackLotus = "Black Lotus"

let urlOpt = createURL(queryItems: [URLQueryItem(name: nameQueryItem, value: nameOpt)])
let urlBlackLotus = createURL(queryItems: [URLQueryItem(name: nameQueryItem, value: nameBlackLotus)])

let requestOpt = createRequest(url: urlOpt)
let requestBlackLotus = createRequest(url: urlBlackLotus)

getData(request: requestOpt) { result in
    switch result {
    case .success(let profile):
        if let cards = profile.cards {
            for card in cards {
                printCardInfo(card)
            }
        }
    case .failure(let error):
        print("Request failed with error: \(error)")
    }
}

getData(request: requestBlackLotus) { result in
    switch result {
    case .success(let profile):
        if let cards = profile.cards {
            for card in cards {
                printCardInfo(card)
            }
        }
    case .failure(let error):
        print("Request failed with error: \(error)")
    }
}
