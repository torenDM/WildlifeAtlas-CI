import Foundation
import Combine

// ViewModel основного экрана.
// Управляет загрузкой наблюдений, состояниями экрана,
// фильтрами и пагинацией, но не содержит SwiftUI-разметки.
@MainActor
final class ExploreViewModel: ObservableObject {

    // Основные mutually exclusive состояния экрана.
    // Загрузка следующей страницы хранится отдельно,
    // чтобы уже загруженный контент не исчезал.
    enum State {
        case loading
        case content
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var observations: [Observation] = []
    @Published private(set) var filters = ObservationFilters()

    // Выбранный таксон храним отдельно от его ID,
    // чтобы интерфейс мог показать пользователю название фильтра.
    @Published private(set) var selectedTaxon: TaxonSelection?

    // Состояние пагинации отделено от основного State.
    @Published private(set) var isLoadingNextPage = false
    @Published private(set) var paginationErrorMessage: String?

    private let service: any INaturalistServiceProtocol
    private let pageSize = 20

    private var currentPage = 0
    private var hasMorePages = true

    // Не позволяет повторно загружать первую страницу
    // при повторном появлении SwiftUI View.
    private var didLoadInitialPage = false

    // Версия текущего набора фильтров.
    // Используется для игнорирования ответов от устаревших
    // async-запросов после изменения фильтра.
    private var queryGeneration = 0

    init(
        service: any INaturalistServiceProtocol =
            INaturalistService()
    ) {
        self.service = service
    }

    // Загружает первую страницу только один раз
    // для текущего жизненного цикла ViewModel.
    func loadInitialPageIfNeeded() async {
        guard !didLoadInitialPage else {
            return
        }

        didLoadInitialPage = true

        await loadInitialPage(
            resetInitialLoadOnCancellation: true
        )
    }

    // Повторная загрузка после ошибки первой страницы.
    func retry() async {
        await loadInitialPage()
    }

    // Изменение фильтра всегда приводит к полной
    // перезагрузке списка с первой страницы.
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

    // Taxon является третьим независимым фильтром.
    // Для API достаточно его ID, а полная TaxonSelection
    // используется только для отображения выбранного значения.
    func setTaxon(
        _ taxon: TaxonSelection?
    ) async {
        guard selectedTaxon != taxon else {
            return
        }

        selectedTaxon = taxon
        filters.taxonID = taxon?.id

        await reloadForFilterChange()
    }

    // Проверка вызывается при появлении элементов списка.
    // Следующая страница загружается только при появлении
    // последнего текущего observation.
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

    // Повторяет только запрос следующей страницы,
    // не перезагружая уже полученный список.
    func retryNextPage() async {
        guard hasMorePages,
              !isLoadingNextPage else {
            return
        }

        await loadNextPage()
    }

    // Сбрасывает состояние пагинации после изменения фильтра.
    private func reloadForFilterChange() async {
        queryGeneration += 1

        observations = []
        currentPage = 0
        hasMorePages = true

        isLoadingNextPage = false
        paginationErrorMessage = nil

        await loadInitialPage()
    }

    // Загружает первую страницу с актуальным набором фильтров.
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

            // Если пользователь успел изменить фильтры,
            // результат старого запроса больше не применяем.
            guard generation == queryGeneration else {
                return
            }

            observations = response.results
            currentPage = response.page

            // API сообщает общее число результатов,
            // поэтому наличие следующей страницы можно определить точно.
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

    // Загружает следующую страницу, сохраняя на экране
    // уже полученные observations.
    private func loadNextPage() async {
        let generation = queryGeneration

        isLoadingNextPage = true
        paginationErrorMessage = nil

        defer {
            // Старый запрос не должен менять состояние
            // после переключения фильтров.
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

    // iNaturalist является изменяемым внешним источником:
    // между запросами границы страниц могут немного сместиться.
    // Поэтому перед добавлением исключаем повторяющиеся ID.
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