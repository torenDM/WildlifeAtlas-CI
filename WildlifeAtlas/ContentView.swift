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
            List(viewModel.observations, id: \.id) { observation in
                Text("Observation #\(observation.id)")
            }

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