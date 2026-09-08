import Foundation

final class INaturalistService {
    private let apiClient: APIClient
    private let baseURL = URL(string: "https://api.inaturalist.org/v1")!

    init(apiClient: APIClient = APIClient()) {
        self.apiClient = apiClient
    }

    func observations(
        page: Int,
        perPage: Int = 20,
        filters: ObservationFilters = ObservationFilters()
    ) async throws -> APIResponse<Observation> {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("observations"),
            resolvingAgainstBaseURL: false
        )

        var queryItems = [
            URLQueryItem(name: "captive", value: "false"),
            URLQueryItem(name: "order_by", value: "observed_on"),
            URLQueryItem(name: "order", value: filters.order.apiValue),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        if let taxonID = filters.taxonID {
            queryItems.append(
                URLQueryItem(
                    name: "taxon_id",
                    value: String(taxonID)
                )
            )
        }

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
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "per_page", value: String(perPage))
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await apiClient.get(
            APIResponse<Taxon>.self,
            from: url
        )
    }

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