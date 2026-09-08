import SwiftUI

// Экран подробной информации об observation.
// Получает только ID, а полные актуальные данные
// загружает через ObservationDetailViewModel.
struct ObservationDetailView: View {

    let observationID: Int

    @EnvironmentObject private var favoritesStore:
    FavoritesStore

    @StateObject private var viewModel =
        ObservationDetailViewModel()

    var body: some View {
        content
            .navigationTitle("Observation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(
                    placement: .topBarTrailing
                ) {
                    if let observation =
                        viewModel.observation {
                        Button {
                            favoritesStore.toggle(
                                observation
                            )
                        } label: {
                            Image(
                                systemName:
                                    favoritesStore.contains(
                                        id: observation.id
                                    )
                                    ? "heart.fill"
                                    : "heart"
                            )
                        }
                        .accessibilityLabel(
                            favoritesStore.contains(
                                id: observation.id
                            )
                            ? "Remove from favorites"
                            : "Add to favorites"
                        )
                    }

                    if let shareURL {
                        ShareLink(item: shareURL) {
                            Image(
                                systemName:
                                    "square.and.arrow.up"
                            )
                        }
                        .accessibilityLabel(
                            "Share observation"
                        )
                    }
                }
            }
            .task {
                await viewModel.loadIfNeeded(
                    id: observationID
                )
            }
    }

    @ViewBuilder
    private var content: some View {
        switch viewModel.state {

        case .loading:
            ProgressView("Loading observation...")

        case .content:
            if let observation = viewModel.observation {
                detailContent(observation)
            } else {
                unavailableContent
            }

        case .empty:
            ContentUnavailableView {
                Label(
                    "Observation not found",
                    systemImage: "binoculars"
                )
            } description: {
                Text(
                    "The observation is no longer available."
                )
            } actions: {
                retryButton
            }

        case .error(let message):
            ContentUnavailableView {
                Label(
                    "Unable to load observation",
                    systemImage: "exclamationmark.triangle"
                )
            } description: {
                Text(message)
            } actions: {
                retryButton
            }
        }
    }

    private func detailContent(
        _ observation: Observation
    ) -> some View {
        let photoURLs = photoURLs(
            for: observation
        )

        return ScrollView {
            VStack(
                alignment: .leading,
                spacing: 24
            ) {
                if !photoURLs.isEmpty {
                    photoGallery(
                        urls: photoURLs
                    )
                }

                namesSection(
                    observation
                )

                observationSection(
                    observation
                )

                if observation.user != nil {
                    authorSection(
                        observation
                    )
                }

                if observation.taxon != nil {
                    taxonomySection(
                        observation
                    )
                }

                if let location =
                    ObservationPrivacy.approximateLocation(
                        for: observation
                    ) {
                    locationSection(
                        location
                    )
                }

                if photoAttribution(
                    for: observation
                ) != nil
                    ||
                    photoLicense(
                        for: observation
                    ) != nil {
                    photoInformationSection(
                        observation
                    )
                }
            }
            .padding()
        }
    }

    @ViewBuilder
    private func namesSection(
        _ observation: Observation
    ) -> some View {
        let commonName = nonEmpty(
            observation.taxon?.preferredCommonName
        )

        let scientificName = nonEmpty(
            observation.taxon?.name
        )

        if commonName != nil
            || scientificName != nil {
            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                if let commonName {
                    Text(commonName)
                        .font(.title2.weight(.bold))
                }

                if let scientificName {
                    Text(scientificName)
                        .font(.headline)
                        .italic()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func observationSection(
        _ observation: Observation
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 12
        ) {
            Text("Observation")
                .font(.headline)

            if let observedOn = nonEmpty(
                observation.observedOn
            ) {
                Label(
                    observedOn,
                    systemImage: "calendar"
                )
            }

            Label(
                qualityTitle(
                    observation.qualityGrade
                ),
                systemImage: "checkmark.seal"
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    @ViewBuilder
    private func authorSection(
        _ observation: Observation
    ) -> some View {
        if let user = observation.user {
            VStack(
                alignment: .leading,
                spacing: 8
            ) {
                Text("Author")
                    .font(.headline)

                if let name = nonEmpty(user.name) {
                    Text(name)
                        .font(.body)

                    Text("@\(user.login)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("@\(user.login)")
                        .font(.body)
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    @ViewBuilder
    private func taxonomySection(
        _ observation: Observation
    ) -> some View {
        if let taxon = observation.taxon {
            VStack(
                alignment: .leading,
                spacing: 12
            ) {
                Text("Taxonomy")
                    .font(.headline)

                if let ancestors = taxon.ancestors {
                    ForEach(ancestors) { ancestor in
                        taxonomyRow(
                            rank: ancestor.rank,
                            scientificName: ancestor.name,
                            commonName:
                                ancestor.preferredCommonName
                        )
                    }
                }

                taxonomyRow(
                    rank: taxon.rank,
                    scientificName: taxon.name,
                    commonName:
                        taxon.preferredCommonName
                )
            }
            .frame(
                maxWidth: .infinity,
                alignment: .leading
            )
        }
    }

    private func taxonomyRow(
        rank: String?,
        scientificName: String,
        commonName: String?
    ) -> some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            Text(
                rankTitle(rank)
                    ?? "Taxon"
            )
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(
                width: 80,
                alignment: .leading
            )

            VStack(
                alignment: .leading,
                spacing: 2
            ) {
                Text(scientificName)
                    .italic()

                if let commonName = nonEmpty(
                    commonName
                ) {
                    Text(commonName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)
        }
    }

    private func locationSection(
        _ location: String
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Approximate location")
                .font(.headline)

            Label(
                location,
                systemImage: "mappin.and.ellipse"
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func photoInformationSection(
        _ observation: Observation
    ) -> some View {
        VStack(
            alignment: .leading,
            spacing: 8
        ) {
            Text("Photo information")
                .font(.headline)

            if let attribution = photoAttribution(
                for: observation
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("Attribution")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(attribution)
                }
            }

            if let license = photoLicense(
                for: observation
            ) {
                VStack(
                    alignment: .leading,
                    spacing: 2
                ) {
                    Text("License")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(license)
                }
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
    }

    private func photoGallery(
        urls: [URL]
    ) -> some View {
        TabView {
            ForEach(
                Array(urls.enumerated()),
                id: \.offset
            ) { _, url in
                detailImage(url: url)
            }
        }
        .frame(height: 320)
        .tabViewStyle(
            .page(indexDisplayMode: .automatic)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 16)
        )
    }

    @ViewBuilder
    private func detailImage(
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
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
        .clipped()
        .accessibilityLabel("Observation photo")
    }

    private var unavailableContent: some View {
        ContentUnavailableView {
            Label(
                "Observation unavailable",
                systemImage: "binoculars"
            )
        } description: {
            Text(
                "Observation data could not be displayed."
            )
        } actions: {
            retryButton
        }
    }

    private var retryButton: some View {
        Button("Retry") {
            Task {
                await viewModel.retry(
                    id: observationID
                )
            }
        }
    }

    private var shareURL: URL? {
        guard
            let value = viewModel.observation?.uri?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !value.isEmpty,
            let url = URL(string: value),
            url.scheme != nil
        else {
            return nil
        }

        return url
    }

    private func photoURLs(
        for observation: Observation
    ) -> [URL] {
        observation.photos.compactMap {
            photoURL(for: $0)
        }
    }

    private func photoURL(
        for photo: INaturalistPhoto
    ) -> URL? {
        let candidates = [
            photo.mediumUrl,
            photo.squareUrl,
            photo.url
        ]

        for candidate in candidates {
            if let candidate,
               let url = URL(string: candidate) {
                return url
            }
        }

        return nil
    }

    private func photoAttribution(
        for observation: Observation
    ) -> String? {
        for photo in observation.photos {
            if let attribution = nonEmpty(
                photo.attribution
            ) {
                return attribution
            }

            if let attributionName = nonEmpty(
                photo.attributionName
            ) {
                return attributionName
            }
        }

        return nil
    }

    private func photoLicense(
        for observation: Observation
    ) -> String? {
        for photo in observation.photos {
            if let license = nonEmpty(
                photo.licenseCode
            ) {
                return license.uppercased()
            }
        }

        return nil
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

    private func rankTitle(
        _ value: String?
    ) -> String? {
        guard let value = nonEmpty(value) else {
            return nil
        }

        return value
            .replacingOccurrences(
                of: "_",
                with: " "
            )
            .capitalized
    }

    private func nonEmpty(
        _ value: String?
    ) -> String? {
        guard let value = value?
            .trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}