import SwiftUI

struct ContentView: View {

    @StateObject private var viewModel = ExploreViewModel()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Wildlife Atlas")
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
            List {
                ForEach(viewModel.observations) { observation in
                    ObservationRowView(observation: observation)
                        .onAppear {
                            Task {
                                await viewModel.loadNextPageIfNeeded(
                                    currentItem: observation
                                )
                            }
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
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)

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
}