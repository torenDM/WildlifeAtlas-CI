import Foundation

// FoundationNetworking нужен для сборки networking-кода
// вне экосистемы Apple, например при локальной проверке на Windows.
// На iOS все необходимые типы доступны через Foundation.
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

// Низкоуровневый HTTP-клиент приложения.
// Отвечает только за выполнение GET-запросов,
// проверку HTTP-ответа и декодирование JSON.
// Конкретные endpoint'ы iNaturalist здесь не описываются:
// их формирует INaturalistService.
final class APIClient {
    private let session: URLSession
    private let decoder: JSONDecoder

    // URLSession передается через init, чтобы при необходимости
    // можно было подменить его в тестах.
    init(session: URLSession = .shared) {
        self.session = session

        // iNaturalist возвращает ключи в snake_case,
        // а Swift-модели используют camelCase.
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        self.decoder = decoder
    }

    // Универсальный GET-запрос.
    // Метод не знает конкретный тип ответа заранее:
    // вызывающий код передает любой Decodable-тип.
    func get<T: Decodable>(
        _ type: T.Type,
        from url: URL
    ) async throws -> T {
        let data: Data
        let response: URLResponse

        // Отдельно преобразуем ошибки URLSession
        // в единый тип ошибок приложения.
        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw APIError.networkFailed(error)
        }

        // Ожидаем именно HTTP-ответ.
        // Ответ другого типа считаем некорректным.
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // Любой статус вне диапазона 2xx считаем ошибкой API.
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(
                statusCode: httpResponse.statusCode
            )
        }

        // Декодирование также оборачиваем в APIError,
        // чтобы верхние уровни приложения работали
        // с единым набором ошибок.
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }
}