import Foundation
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {

    enum State {
        case loading
        case content
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var observations: [Observation] = []

    private let service: INaturalistService

    private var didLoadInitialPage = false

    init(service: INaturalistService = INaturalistService()) {
        self.service = service
    }

    func loadInitialPageIfNeeded() async {
        guard !didLoadInitialPage else {
            return
        }

        didLoadInitialPage = true
        await loadInitialPage()
    }

    func retry() async {
        await loadInitialPage()
    }

    private func loadInitialPage() async {
        state = .loading

        do {
            let response = try await service.observations(
                page: 1,
                perPage: 20,
                filters: ObservationFilters()
            )
            observations = response.results

            state = observations.isEmpty
                ? .empty
                : .content

        } catch is CancellationError {
            didLoadInitialPage = false
        } catch {
            observations = []
            state = .error(error.localizedDescription)
        }
    }
}