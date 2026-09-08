import SwiftUI

struct ContentView: View {

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
                    ToolbarItem(placement: .topBarTrailing) {
                        layoutPicker
                    }
                }
        }
        .task {
            await viewModel.loadInitialPageIfNeeded()
        }
    }

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
                description: Text("No observations were found.")
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
                ObservationRowView(observation: observation)
                    .onAppear {
                        requestNextPageIfNeeded(
                            for: observation
                        )
                    }
            }

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

    private var layoutPicker: some View {
        Picker("Display mode", selection: $layout) {
            Image(systemName: "list.bullet")
                .tag(ExploreLayout.list)

            Image(systemName: "square.grid.2x2")
                .tag(ExploreLayout.grid)
        }
        .pickerStyle(.segmented)
        .frame(width: 90)
        .accessibilityLabel("Display mode")
    }

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