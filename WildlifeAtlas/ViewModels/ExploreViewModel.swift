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

    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var paginationErrorMessage: String?

    private let service: INaturalistService

    private let pageSize = 20

    private var currentPage = 0
    private var hasMorePages = true
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

    func loadNextPageIfNeeded(currentItem: Observation) async {
        guard stateIsContent,
              hasMorePages,
              !isLoadingNextPage,
              currentItem.id == observations.last?.id else {
            return
        }

        await loadNextPage()
    }

    func retryNextPage() async {
        guard hasMorePages,
              !isLoadingNextPage else {
            return
        }

        await loadNextPage()
    }

    private func loadInitialPage() async {
        state = .loading
        paginationErrorMessage = nil

        do {
            let response = try await service.observations(
                page: 1,
                perPage: pageSize,
                filters: ObservationFilters()
            )

            observations = response.results
            currentPage = response.page

            hasMorePages =
                response.page * response.perPage < response.totalResults

            state = observations.isEmpty
                ? .empty
                : .content

        } catch is CancellationError {
            didLoadInitialPage = false
        } catch {
            observations = []
            currentPage = 0
            hasMorePages = true

            state = .error(error.localizedDescription)
        }
    }

    private func loadNextPage() async {
        isLoadingNextPage = true
        paginationErrorMessage = nil

        defer {
            isLoadingNextPage = false
        }

        do {
            let nextPage = currentPage + 1

            let response = try await service.observations(
                page: nextPage,
                perPage: pageSize,
                filters: ObservationFilters()
            )

            appendUnique(response.results)

            currentPage = response.page

            hasMorePages =
                response.page * response.perPage < response.totalResults

        } catch is CancellationError {
            return
        } catch {
            paginationErrorMessage = error.localizedDescription
        }
    }

    private func appendUnique(_ newObservations: [Observation]) {
        let existingIDs = Set(observations.map(\.id))

        let uniqueObservations = newObservations.filter {
            !existingIDs.contains($0.id)
        }

        observations.append(contentsOf: uniqueObservations)
    }

    private var stateIsContent: Bool {
        if case .content = state {
            return true
        }

        return false
    }
}