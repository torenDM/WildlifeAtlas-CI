import SwiftUI

// Отдельный экран выбора таксона.
// При выборе возвращает компактный TaxonSelection
// родительскому Explore-экрану.
struct TaxonSearchView: View {

    @Environment(\.dismiss) private var dismiss

    @StateObject private var viewModel =
        TaxonSearchViewModel()

    let selectedTaxon: TaxonSelection?
    let onSelect: (TaxonSelection) -> Void

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Select taxon")
                .navigationBarTitleDisplayMode(.inline)
                .searchable(
                    text: $viewModel.query,
                    prompt: "Search taxon"
                )
                .toolbar {
                    ToolbarItem(
                        placement: .topBarTrailing
                    ) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }

    // До начала ввода показываем историю,
    // после ввода — состояние autocomplete.
    @ViewBuilder
    private var content: some View {
        switch viewModel.state {

        case .idle:
            recentContent

        case .loading:
            VStack {
                Spacer()

                ProgressView("Searching...")

                Spacer()
            }

        case .results:
            searchResults

        case .empty:
            ContentUnavailableView(
                "No taxa found",
                systemImage: "magnifyingglass",
                description: Text(
                    "Try another search query."
                )
            )

        case .error(let message):
            ContentUnavailableView {
                Label(
                    "Unable to search",
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    viewModel.retrySearch()
                }
            }
        }
    }

    @ViewBuilder
    private var recentContent: some View {
        if viewModel.recentTaxa.isEmpty {
            ContentUnavailableView(
                "Search for a taxon",
                systemImage: "magnifyingglass",
                description: Text(
                    "Start typing a common or scientific name."
                )
            )
        } else {
            List {
                Section("Recently selected") {
                    ForEach(viewModel.recentTaxa) { taxon in
                        Button {
                            select(taxon)
                        } label: {
                            taxonRow(
                                taxon,
                                isSelected:
                                    selectedTaxon?.id
                                    == taxon.id
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var searchResults: some View {
        List(viewModel.results) { taxon in
            let selection = TaxonSelection(
                taxon: taxon
            )

            Button {
                select(selection)
            } label: {
                taxonRow(
                    selection,
                    isSelected:
                        selectedTaxon?.id
                        == selection.id
                )
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
    }

    // Common name показываем основным,
    // scientific name — вторичным курсивом.
    private func taxonRow(
        _ taxon: TaxonSelection,
        isSelected: Bool
    ) -> some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                if let commonName = taxon.commonName {
                    Text(commonName)
                        .font(.headline)

                    Text(taxon.scientificName)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                } else {
                    Text(taxon.scientificName)
                        .font(.headline)
                        .italic()
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
            }
        }
        .contentShape(Rectangle())
    }

    private func select(
        _ taxon: TaxonSelection
    ) {
        viewModel.recordSelection(taxon)
        onSelect(taxon)
        dismiss()
    }
}