import SwiftUI

// Локальный список сохраненных observation.
// Для построения списка API не вызывается:
// используются snapshots из FavoritesStore.
struct FavoritesView: View {

    @EnvironmentObject private var favoritesStore:
        FavoritesStore

    var body: some View {
        content
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var content: some View {
        if favoritesStore.favorites.isEmpty {
            ContentUnavailableView(
                "No favorites",
                systemImage: "heart",
                description: Text(
                    "Observations you save will appear here."
                )
            )
        } else {
            List {
                ForEach(
                    favoritesStore.favorites
                ) { favorite in
                    NavigationLink {
                        ObservationDetailView(
                            observationID: favorite.id
                        )
                    } label: {
                        favoriteRow(favorite)
                    }
                }
                .onDelete {
                    favoritesStore.remove(
                        at: $0
                    )
                }
            }
            .listStyle(.plain)
        }
    }

    private func favoriteRow(
        _ favorite: FavoriteObservation
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            if let photoURL = photoURL(
                for: favorite
            ) {
                thumbnail(url: photoURL)
            }

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                if let commonName =
                    favorite.commonName {
                    Text(commonName)
                        .font(.headline)
                        .lineLimit(2)
                }

                if let scientificName =
                    favorite.scientificName {
                    Text(scientificName)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if favorite.commonName == nil
                    && favorite.scientificName == nil {
                    Text(
                        "Observation #\(favorite.id)"
                    )
                    .font(.headline)
                }

                if let observedOn =
                    favorite.observedOn {
                    Label(
                        observedOn,
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Text(
                    qualityTitle(
                        favorite.qualityGrade
                    )
                )
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func thumbnail(
        url: URL
    ) -> some View {
        CachedAsyncImage(url: url) { phase in
            switch phase {

            case .empty:
                ZStack {
                    Rectangle()
                        .fill(.quaternary)

                    ProgressView()
                }

            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()

            case .failure:
                ZStack {
                    Rectangle()
                        .fill(.quaternary)

                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityLabel(
            "Observation photo"
        )
    }

    private func photoURL(
        for favorite: FavoriteObservation
    ) -> URL? {
        guard
            let value = favorite.photoURL,
            let url = URL(string: value)
        else {
            return nil
        }

        return url
    }

    private func qualityTitle(
        _ value: String
    ) -> String {
        switch value {

        case "research":
            return "Research"

        case "needs_id":
            return "Needs ID"

        case "casual":
            return "Casual"

        default:
            return value
                .replacingOccurrences(
                    of: "_",
                    with: " "
                )
                .capitalized
        }
    }
}