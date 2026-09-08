import SwiftUI

// Карточка observation для Grid-режима.
// В отличие от List использует вертикальную композицию
// с крупным квадратным изображением.
struct ObservationGridItemView: View {

    let observation: Observation

    var body: some View {
        VStack(
            alignment: .leading,
            spacing: 10
        ) {
            photo

            VStack(
                alignment: .leading,
                spacing: 6
            ) {
                if let commonName {
                    Text(commonName)
                        .font(.headline)
                        .lineLimit(2)
                }

                if let scientificName {
                    Text(scientificName)
                        .font(.subheadline)
                        .italic()
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                if commonName == nil
                    && scientificName == nil {
                    Text(
                        "Observation #\(observation.id)"
                    )
                    .font(.headline)
                }

                if let observedOn {
                    Label(
                        observedOn,
                        systemImage: "calendar"
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                }

                Text(qualityTitle)
                    .font(
                        .caption.weight(.semibold)
                    )
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.quaternary)
                    .clipShape(Capsule())
            }
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(10)
        .background(.thinMaterial)
        .clipShape(
            RoundedRectangle(
                cornerRadius: 16
            )
        )
        .accessibilityElement(
            children: .combine
        )
    }

    @ViewBuilder
    private var photo: some View {
        if let photoURL {
            thumbnail(url: photoURL)
        } else {
            photoPlaceholder
        }
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
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(
            1,
            contentMode: .fit
        )
        .clipped()
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .accessibilityHidden(true)
    }

    private var photoPlaceholder: some View {
        ZStack {
            Rectangle()
                .fill(.quaternary)

            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(
            1,
            contentMode: .fit
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .accessibilityHidden(true)
    }

    private var photoURL: URL? {
        guard let photo =
            observation.photos.first else {
            return nil
        }

        let candidates = [
            photo.mediumUrl,
            photo.squareUrl,
            photo.url
        ]

        for candidate in candidates {
            if let candidate,
               let url = URL(
                    string: candidate
               ) {
                return url
            }
        }

        return nil
    }

    private var commonName: String? {
        ObservationPresentation.nonEmpty(
            observation.taxon?
                .preferredCommonName
        )
    }

    private var scientificName: String? {
        ObservationPresentation.nonEmpty(
            observation.taxon?.name
        )
    }

    private var observedOn: String? {
        ObservationPresentation.observedDate(
            observation.observedOn
        )
    }

    private var qualityTitle: String {
        ObservationPresentation.qualityTitle(
            observation.qualityGrade
        )
    }
}