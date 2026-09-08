import Foundation
import Combine

// ViewModel autocomplete-поиска таксонов.
// Управляет debounce, результатами поиска
// и локальной историей последних выбранных таксонов.
@MainActor
final class TaxonSearchViewModel: ObservableObject {

    enum State {
        case idle
        case loading
        case results
        case empty
        case error(String)
    }

    // Изменение query автоматически запускает
    // отложенный autocomplete-запрос.
    @Published var query: String = "" {
        didSet {
            scheduleSearch()
        }
    }

    @Published private(set) var state: State = .idle
    @Published private(set) var results: [Taxon] = []
    @Published private(set) var recentTaxa: [TaxonSelection] = []

    private let service: any INaturalistServiceProtocol
    private let userDefaults: UserDefaults

    private let recentTaxaKey = "recentTaxa"
    private let maximumRecentTaxa = 5

    // Храним Task, чтобы отменять предыдущий debounce
    // при вводе следующего символа.
    private var searchTask: Task<Void, Never>?

    init(
        service: any INaturalistServiceProtocol = INaturalistService(),
        userDefaults: UserDefaults = .standard
    ) {
        self.service = service
        self.userDefaults = userDefaults

        loadRecentTaxa()
    }

    // Повторяет поиск после error-state без дополнительного debounce.
    func retrySearch() {
        let normalizedQuery = normalized(query)

        guard !normalizedQuery.isEmpty else {
            return
        }

        searchTask?.cancel()
        state = .loading

        searchTask = Task { [weak self] in
            guard let self else {
                return
            }

            await self.performSearch(
                query: normalizedQuery
            )
        }
    }

    // Обновляет историю: выбранный таксон перемещается наверх,
    // повторяющиеся ID не сохраняются.
    func recordSelection(
        _ selection: TaxonSelection
    ) {
        recentTaxa.removeAll {
            $0.id == selection.id
        }

        recentTaxa.insert(selection, at: 0)

        if recentTaxa.count > maximumRecentTaxa {
            recentTaxa = Array(
                recentTaxa.prefix(maximumRecentTaxa)
            )
        }

        saveRecentTaxa()
    }

    // Debounce уменьшает число запросов во время быстрого ввода.
    // Запрос отправляется только через 350 мс после последнего символа.
    private func scheduleSearch() {
        searchTask?.cancel()

        let normalizedQuery = normalized(query)

        guard !normalizedQuery.isEmpty else {
            results = []
            state = .idle
            return
        }

        state = .loading

        searchTask = Task { [weak self] in
            do {
                try await Task.sleep(
                    nanoseconds: 350_000_000
                )
            } catch {
                return
            }

            guard !Task.isCancelled,
                  let self else {
                return
            }

            await self.performSearch(
                query: normalizedQuery
            )
        }
    }

    private func performSearch(
        query searchedQuery: String
    ) async {
        do {
            let response = try await service.searchTaxa(
                query: searchedQuery,
                perPage: 10
            )

            // Пока выполнялся запрос пользователь мог изменить текст.
            // В этом случае результат старого запроса игнорируем.
            guard searchedQuery == normalized(query) else {
                return
            }

            results = response.results

            state = results.isEmpty
                ? .empty
                : .results

        } catch is CancellationError {
            return

        } catch {
            guard searchedQuery == normalized(query) else {
                return
            }

            results = []
            state = .error(error.localizedDescription)
        }
    }

    // Последние выбранные таксоны сохраняются между запусками приложения.
    private func loadRecentTaxa() {
        guard
            let data = userDefaults.data(
                forKey: recentTaxaKey
            ),
            let storedTaxa = try? JSONDecoder().decode(
                [TaxonSelection].self,
                from: data
            )
        else {
            return
        }

        recentTaxa = Array(
            storedTaxa.prefix(maximumRecentTaxa)
        )
    }

    private func saveRecentTaxa() {
        guard let data = try? JSONEncoder().encode(
            recentTaxa
        ) else {
            return
        }

        userDefaults.set(
            data,
            forKey: recentTaxaKey
        )
    }

    private func normalized(
        _ value: String
    ) -> String {
        value.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
    }
}