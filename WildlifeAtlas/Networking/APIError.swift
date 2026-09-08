import Foundation

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int)
    case decodingFailed(Error)
    case networkFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Не удалось сформировать адрес запроса."

        case .invalidResponse:
            return "Сервер вернул некорректный ответ."

        case .httpError(let statusCode):
            return "Ошибка сервера. Код: \(statusCode)."

        case .decodingFailed:
            return "Не удалось обработать ответ сервера."

        case .networkFailed:
            return "Не удалось выполнить сетевой запрос."
        }
    }
}