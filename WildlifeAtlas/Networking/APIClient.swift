import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    func get<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) async throws -> T {
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.networkFailed(error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(statusCode: httpResponse.statusCode)
        }

        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}