import XCTest
@testable import WildlifeAtlasCore

final class MockINaturalistService:
    INaturalistServiceProtocol {

    struct ObservationRequest {
        let page: Int
        let perPage: Int
        let filters: ObservationFilters
    }

    enum MockError: Error {
        case notImplemented
        case failed
    }

    var observationRequests:
        [ObservationRequest] = []

    var observationsHandler:
        ((Int, Int, ObservationFilters) async throws
            -> APIResponse<Observation>)?

    var observationHandler:
        ((Int) async throws -> Observation)?

    func observations(
        page: Int,
        perPage: Int,
        filters: ObservationFilters
    ) async throws -> APIResponse<Observation> {
        observationRequests.append(
            ObservationRequest(
                page: page,
                perPage: perPage,
                filters: filters
            )
        )

        guard let observationsHandler else {
            throw MockError.notImplemented
        }

        return try await observationsHandler(
            page,
            perPage,
            filters
        )
    }

    func searchTaxa(
        query: String,
        perPage: Int
    ) async throws -> APIResponse<Taxon> {
        throw MockError.notImplemented
    }

    func observation(
        id: Int
    ) async throws -> Observation {
        guard let observationHandler else {
            throw MockError.notImplemented
        }

        return try await observationHandler(id)
    }
}

@MainActor
final class ExploreViewModelTests: XCTestCase {

    func testInitialLoadProducesContent() async {
        let service = MockINaturalistService()

        service.observationsHandler = {
            _, _, _ in

            APIResponse(
                totalResults: 1,
                page: 1,
                perPage: 20,
                results: [
                    makeObservation(id: 1)
                ]
            )
        }

        let viewModel = ExploreViewModel(
            service: service
        )

        await viewModel.loadInitialPageIfNeeded()

        XCTAssertEqual(
            viewModel.observations.map(\.id),
            [1]
        )

        if case .content = viewModel.state {
            // Expected state.
        } else {
            XCTFail("Expected content state.")
        }
    }

    func testEmptyResponseProducesEmptyState() async {
        let service = MockINaturalistService()

        service.observationsHandler = {
            _, _, _ in

            APIResponse(
                totalResults: 0,
                page: 1,
                perPage: 20,
                results: []
            )
        }

        let viewModel = ExploreViewModel(
            service: service
        )

        await viewModel.loadInitialPageIfNeeded()

        XCTAssertTrue(
            viewModel.observations.isEmpty
        )

        if case .empty = viewModel.state {
            // Expected state.
        } else {
            XCTFail("Expected empty state.")
        }
    }

    func testFilterChangeKeepsOtherFiltersAndReloadsPageOne()
        async {

        let service = MockINaturalistService()

        service.observationsHandler = {
            _, _, _ in

            APIResponse(
                totalResults: 1,
                page: 1,
                perPage: 20,
                results: [
                    makeObservation(id: 1)
                ]
            )
        }

        let viewModel = ExploreViewModel(
            service: service
        )

        await viewModel.loadInitialPageIfNeeded()

        await viewModel.setQuality(
            .research
        )

        let redFox = TaxonSelection(
            id: 42069,
            scientificName: "Vulpes vulpes",
            commonName: "Red Fox"
        )

        await viewModel.setTaxon(redFox)

        guard let request =
            service.observationRequests.last else {
            XCTFail("Expected API request.")
            return
        }

        XCTAssertEqual(
            request.page,
            1
        )

        XCTAssertEqual(
            request.filters.taxonID,
            42069
        )

        XCTAssertEqual(
            request.filters.quality.rawValue,
            QualityFilter.research.rawValue
        )

        XCTAssertEqual(
            request.filters.order.rawValue,
            ObservationOrder.newest.rawValue
        )
    }

    func testPaginationAppendsOnlyUniqueObservations()
        async {

        let service = MockINaturalistService()

        service.observationsHandler = {
            page, _, _ in

            if page == 1 {
                return APIResponse(
                    totalResults: 40,
                    page: 1,
                    perPage: 20,
                    results: [
                        makeObservation(id: 1),
                        makeObservation(id: 2)
                    ]
                )
            }

            return APIResponse(
                totalResults: 40,
                page: 2,
                perPage: 20,
                results: [
                    makeObservation(id: 2),
                    makeObservation(id: 3)
                ]
            )
        }

        let viewModel = ExploreViewModel(
            service: service
        )

        await viewModel.loadInitialPageIfNeeded()

        guard let last =
            viewModel.observations.last else {
            XCTFail("Expected initial observations.")
            return
        }

        await viewModel.loadNextPageIfNeeded(
            currentItem: last
        )

        XCTAssertEqual(
            viewModel.observations.map(\.id),
            [1, 2, 3]
        )

        XCTAssertEqual(
            service.observationRequests.map(\.page),
            [1, 2]
        )
    }

    func testInitialFailureProducesErrorState()
        async {

        let service = MockINaturalistService()

        service.observationsHandler = {
            _, _, _ in

            throw MockINaturalistService
                .MockError.failed
        }

        let viewModel = ExploreViewModel(
            service: service
        )

        await viewModel.loadInitialPageIfNeeded()

        if case .error = viewModel.state {
            // Expected state.
        } else {
            XCTFail("Expected error state.")
        }
    }
}

@MainActor
final class ObservationDetailViewModelTests:
    XCTestCase {

    func testDetailLoadsObservationByID() async {
        let service = MockINaturalistService()

        service.observationHandler = { id in
            makeObservation(id: id)
        }

        let viewModel = ObservationDetailViewModel(
            service: service
        )

        await viewModel.loadIfNeeded(id: 42)

        XCTAssertEqual(
            viewModel.observation?.id,
            42
        )

        if case .content = viewModel.state {
            // Expected state.
        } else {
            XCTFail("Expected content state.")
        }
    }
}

final class ObservationPrivacyTests:
    XCTestCase {

    func testPublicApproximateLocationIsVisible() {
        let observation = makeObservation(
            id: 1,
            placeGuess: "Amsterdam, Netherlands"
        )

        XCTAssertEqual(
            ObservationPrivacy.approximateLocation(
                for: observation
            ),
            "Amsterdam, Netherlands"
        )
    }

    func testObscuredLocationIsHidden() {
        let observation = makeObservation(
            id: 1,
            placeGuess: "Amsterdam, Netherlands",
            obscured: true
        )

        XCTAssertNil(
            ObservationPrivacy.approximateLocation(
                for: observation
            )
        )
    }

    func testPrivateLocationIsHidden() {
        let observation = makeObservation(
            id: 1,
            placeGuess: "Amsterdam, Netherlands",
            geoprivacy: "private"
        )

        XCTAssertNil(
            ObservationPrivacy.approximateLocation(
                for: observation
            )
        )
    }
}

@MainActor
final class FavoritesStoreTests: XCTestCase {

    func testFavoritePersistsInUserDefaults() {
        let suiteName =
            "FavoritesStoreTests-\(UUID().uuidString)"

        guard let userDefaults =
            UserDefaults(suiteName: suiteName) else {
            XCTFail(
                "Unable to create isolated UserDefaults."
            )
            return
        }

        defer {
            userDefaults.removePersistentDomain(
                forName: suiteName
            )
        }

        let store = FavoritesStore(
            userDefaults: userDefaults
        )

        let observation =
            makeObservation(id: 10)

        store.toggle(observation)

        XCTAssertTrue(
            store.contains(id: 10)
        )

        let restoredStore = FavoritesStore(
            userDefaults: userDefaults
        )

        XCTAssertTrue(
            restoredStore.contains(id: 10)
        )
    }
}

private func makeObservation(
    id: Int,
    placeGuess: String? = nil,
    obscured: Bool = false,
    geoprivacy: String? = nil,
    taxonGeoprivacy: String? = nil
) -> Observation {
    Observation(
        id: id,
        qualityGrade: "research",
        timeObservedAt: nil,
        observedOn: "2026-09-08",
        speciesGuess: nil,
        captive: false,
        taxon: nil,
        photos: [],
        user: nil,
        placeGuess: placeGuess,
        obscured: obscured,
        geoprivacy: geoprivacy,
        taxonGeoprivacy: taxonGeoprivacy,
        uri: nil,
        description: nil
    )
}