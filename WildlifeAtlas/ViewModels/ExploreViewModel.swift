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
    @Published private(set) var filters = ObservationFilters()

    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var paginationErrorMessage: String?

    private let service: INaturalistService
    private let pageSize = 20

    private var currentPage = 0
    private var hasMorePages = true
    private var didLoadInitialPage = false

    private var queryGeneration = 0

    init(service: INaturalistService = INaturalistService()) {
        self.service = service
    }

    func loadInitialPageIfNeeded() async {
        guard !didLoadInitialPage else {
            return
        }

        didLoadInitialPage = true

        await loadInitialPage(
            resetInitialLoadOnCancellation: true
        )
    }

    func retry() async {
        await loadInitialPage()
    }

    func setQuality(_ quality: QualityFilter) async {
        guard filters.quality.rawValue != quality.rawValue else {
            return
        }

        filters.quality = quality
        await reloadForFilterChange()
    }

    func setOrder(_ order: ObservationOrder) async {
        guard filters.order.rawValue != order.rawValue else {
            return
        }

        filters.order = order
        await reloadForFilterChange()
    }

    func loadNextPageIfNeeded(
        currentItem: Observation
    ) async {
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

    private func reloadForFilterChange() async {
        queryGeneration += 1

        observations = []
        currentPage = 0
        hasMorePages = true

        isLoadingNextPage = false
        paginationErrorMessage = nil

        await loadInitialPage()
    }

    private func loadInitialPage(
        resetInitialLoadOnCancellation: Bool = false
    ) async {
        let generation = queryGeneration

        state = .loading
        paginationErrorMessage = nil

        do {
            let response = try await service.observations(
                page: 1,
                perPage: pageSize,
                filters: filters
            )

            guard generation == queryGeneration else {
                return
            }

            observations = response.results
            currentPage = response.page

            hasMorePages =
                response.page * response.perPage
                < response.totalResults

            state = observations.isEmpty
                ? .empty
                : .content

        } catch is CancellationError {
            if resetInitialLoadOnCancellation,
               generation == queryGeneration {
                didLoadInitialPage = false
            }

        } catch {
            guard generation == queryGeneration else {
                return
            }

            observations = []
            currentPage = 0
            hasMorePages = true

            state = .error(error.localizedDescription)
        }
    }

    private func loadNextPage() async {
        let generation = queryGeneration

        isLoadingNextPage = true
        paginationErrorMessage = nil

        defer {
            if generation == queryGeneration {
                isLoadingNextPage = false
            }
        }

        do {
            let nextPage = currentPage + 1

            let response = try await service.observations(
                page: nextPage,
                perPage: pageSize,
                filters: filters
            )

            guard generation == queryGeneration else {
                return
            }

            appendUnique(response.results)

            currentPage = response.page

            hasMorePages =
                response.page * response.perPage
                < response.totalResults

        } catch is CancellationError {
            return

        } catch {
            guard generation == queryGeneration else {
                return
            }

            paginationErrorMessage =
                error.localizedDescription
        }
    }

    private func appendUnique(
        _ newObservations: [Observation]
    ) {
        let existingIDs = Set(
            observations.map(\.id)
        )

        let uniqueObservations =
            newObservations.filter {
                !existingIDs.contains($0.id)
            }

        observations.append(
            contentsOf: uniqueObservations
        )
    }

    private var stateIsContent: Bool {
        if case .content = state {
            return true
        }

        return false
    }
}