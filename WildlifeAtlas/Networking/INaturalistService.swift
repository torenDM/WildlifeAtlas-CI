import Foundation

// Абстракция networking-сервиса.
// ViewModel зависят от протокола, поэтому в unit-тестах
// реальный iNaturalist API можно заменить контролируемым mock.
protocol INaturalistServiceProtocol {
    func observations(
        page: Int,
        perPage: Int,
        filters: ObservationFilters
    ) async throws -> APIResponse<Observation>

    func searchTaxa(
        query: String,
        perPage: Int
    ) async throws -> APIResponse<Taxon>

    func observation(
        id: Int
    ) async throws -> Observation
}

// Сервис для работы с конкретными endpoint'ами iNaturalist.
// В отличие от APIClient, этот слой знает структуру API:
// пути, query-параметры и типы ожидаемых ответов.
final class INaturalistService: INaturalistServiceProtocol {
    private let apiClient: APIClient

    // Базовый адрес API, от которого строятся все endpoint'ы.
    private let baseURL = URL(
        string: "https://api.inaturalist.org/v1"
    )!

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    // Загружает страницу наблюдений с учетом выбранных фильтров.
    // Пагинация управляется через page/perPage,
    // а сортировка и качество берутся из ObservationFilters.
    func observations(
        page: Int,
        perPage: Int = 20,
        filters: ObservationFilters = ObservationFilters()
    ) async throws -> APIResponse<Observation> {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("observations"),
            resolvingAgainstBaseURL: false
        )

        // Базовые параметры применяются к каждому запросу наблюдений.
        // captive=false — обязательное ограничение задания,
        // поэтому оно не вынесено в пользовательские фильтры.
        var queryItems = [
            URLQueryItem(
                name: "captive",
                value: "false"
            ),
            URLQueryItem(
                name: "order_by",
                value: "observed_on"
            ),
            URLQueryItem(
                name: "order",
                value: filters.order.apiValue
            ),
            URLQueryItem(
                name: "page",
                value: String(page)
            ),
            URLQueryItem(
                name: "per_page",
                value: String(perPage)
            )
        ]

        // Фильтр по таксону добавляется только тогда,
        // когда пользователь действительно выбрал таксон.
        if let taxonID = filters.taxonID {
            queryItems.append(
                URLQueryItem(
                    name: "taxon_id",
                    value: String(taxonID)
                )
            )
        }

        // Для режима Any параметр quality_grade не отправляется.
        // В запрос он попадает только при выборе конкретного качества.
        if let quality = filters.quality.apiValue {
            queryItems.append(
                URLQueryItem(
                    name: "quality_grade",
                    value: quality
                )
            )
        }

        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await apiClient.get(
            APIResponse<Observation>.self,
            from: url
        )
    }

    // Выполняет autocomplete-поиск таксонов.
    // Результаты этого endpoint'а используются
    // при выборе taxon-фильтра на основном экране.
    func searchTaxa(
        query: String,
        perPage: Int = 10
    ) async throws -> APIResponse<Taxon> {
        var components = URLComponents(
            url: baseURL
                .appendingPathComponent("taxa")
                .appendingPathComponent("autocomplete"),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = [
            URLQueryItem(
                name: "q",
                value: query
            ),
            URLQueryItem(
                name: "per_page",
                value: String(perPage)
            )
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await apiClient.get(
            APIResponse<Taxon>.self,
            from: url
        )
    }

    // Загружает подробную информацию об одном наблюдении по ID.
    // API возвращает стандартную обертку с results,
    // поэтому извлекаем первый элемент вручную.
    func observation(
        id: Int
    ) async throws -> Observation {
        let url = baseURL
            .appendingPathComponent("observations")
            .appendingPathComponent(String(id))

        let response = try await apiClient.get(
            APIResponse<Observation>.self,
            from: url
        )

        guard let observation = response.results.first else {
            throw APIError.invalidResponse
        }

        return observation
    }
}