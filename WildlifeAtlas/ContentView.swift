import SwiftUI

// Корневое представление основного экрана Explore.
// Отвечает за композицию интерфейса, тогда как загрузка данных,
// фильтры и пагинация находятся в ExploreViewModel.
struct ContentView: View {

    // Режим отображения является presentation state,
    // поэтому хранится непосредственно во View.
    private enum ExploreLayout {
        case list
        case grid
    }

    @StateObject private var viewModel = ExploreViewModel()
    @State private var layout: ExploreLayout = .list

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Wildlife Atlas")
                .toolbar {
                    ToolbarItemGroup(
                        placement: .topBarTrailing
                    ) {
                        filterMenu
                        layoutPicker
                    }
                }
        }
        // ViewModel самостоятельно защищается
        // от повторной загрузки первой страницы.
        .task {
            await viewModel.loadInitialPageIfNeeded()
        }
    }

    // Основные состояния экрана отображаются независимо:
    // loading, content, empty и error.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {

        case .loading:
            ProgressView("Loading observations...")

        case .content:
            observationsContent

        case .empty:
            ContentUnavailableView(
                "No observations",
                systemImage: "binoculars",
                description: Text(
                    "No observations were found."
                )
            )

        case .error(let message):
            ContentUnavailableView {
                Label(
                    "Unable to load observations",
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task {
                        await viewModel.retry()
                    }
                }
            }
        }
    }

    // List и Grid используют один и тот же массив observations
    // и не инициируют отдельную загрузку данных при переключении.
    @ViewBuilder
    private var observationsContent: some View {
        switch layout {
        case .list:
            listContent

        case .grid:
            gridContent
        }
    }

    private var listContent: some View {
        List {
            ForEach(viewModel.observations) { observation in
                ObservationRowView(
                    observation: observation
                )
                .onAppear {
                    requestNextPageIfNeeded(
                        for: observation
                    )
                }
            }

            // Пагинация не заменяет уже загруженный список
            // общим loading-state.
            if viewModel.isLoadingNextPage {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }

            if viewModel.paginationErrorMessage != nil {
                paginationError
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    private var gridContent: some View {
        ScrollView {
            LazyVGrid(
                columns: [
                    GridItem(
                        .adaptive(minimum: 160),
                        spacing: 12
                    )
                ],
                spacing: 12
            ) {
                ForEach(viewModel.observations) { observation in
                    ObservationGridItemView(
                        observation: observation
                    )
                    .onAppear {
                        requestNextPageIfNeeded(
                            for: observation
                        )
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 8)

            if viewModel.isLoadingNextPage {
                ProgressView()
                    .padding()
            }

            if viewModel.paginationErrorMessage != nil {
                paginationError
                    .padding()
            }
        }
    }

    // Меню содержит два независимых фильтра.
    // Выбор значения передается ViewModel,
    // которая перезагружает список с первой страницы.
    private var filterMenu: some View {
        Menu {
            Section("Quality") {
                Button {
                    Task {
                        await viewModel.setQuality(.any)
                    }
                } label: {
                    if viewModel.filters.quality.rawValue
                        == QualityFilter.any.rawValue {
                        Label(
                            "Any",
                            systemImage: "checkmark"
                        )
                    } else {
                        Text("Any")
                    }
                }

                Button {
                    Task {
                        await viewModel.setQuality(.research)
                    }
                } label: {
                    if viewModel.filters.quality.rawValue
                        == QualityFilter.research.rawValue {
                        Label(
                            "Research",
                            systemImage: "checkmark"
                        )
                    } else {
                        Text("Research")
                    }
                }
            }

            Section("Order") {
                Button {
                    Task {
                        await viewModel.setOrder(.newest)
                    }
                } label: {
                    if viewModel.filters.order.rawValue
                        == ObservationOrder.newest.rawValue {
                        Label(
                            "Newest first",
                            systemImage: "checkmark"
                        )
                    } else {
                        Text("Newest first")
                    }
                }

                Button {
                    Task {
                        await viewModel.setOrder(.oldest)
                    }
                } label: {
                    if viewModel.filters.order.rawValue
                        == ObservationOrder.oldest.rawValue {
                        Label(
                            "Oldest first",
                            systemImage: "checkmark"
                        )
                    } else {
                        Text("Oldest first")
                    }
                }
            }
        } label: {
            // Заполненная иконка показывает,
            // что используются нестандартные фильтры.
            Image(
                systemName: hasNonDefaultFilters
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
        .accessibilityLabel("Filters")
    }

    private var hasNonDefaultFilters: Bool {
        viewModel.filters.quality.rawValue
            != QualityFilter.any.rawValue
            ||
        viewModel.filters.order.rawValue
            != ObservationOrder.newest.rawValue
    }

    // Переключение List/Grid меняет только представление,
    // не затрагивая загруженные observations.
    private var layoutPicker: some View {
        Picker(
            "Display mode",
            selection: $layout
        ) {
            Image(systemName: "list.bullet")
                .tag(ExploreLayout.list)

            Image(systemName: "square.grid.2x2")
                .tag(ExploreLayout.grid)
        }
        .pickerStyle(.segmented)
        .frame(width: 90)
        .accessibilityLabel("Display mode")
    }

    // Ошибка следующей страницы отображается отдельно,
    // чтобы пользователь не терял уже загруженный контент.
    private var paginationError: some View {
        VStack(spacing: 8) {
            Text("Unable to load more observations")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("Retry") {
                Task {
                    await viewModel.retryNextPage()
                }
            }
            .font(.caption.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
    }

    // View сообщает только о появлении элемента.
    // Решение о необходимости запроса следующей страницы
    // принимает ExploreViewModel.
    private func requestNextPageIfNeeded(
        for observation: Observation
    ) {
        Task {
            await viewModel.loadNextPageIfNeeded(
                currentItem: observation
            )
        }
    }
}