import SwiftUI

// Представление одного observation в режиме списка.
struct ObservationRowView: View {

    let observation: Observation

    var body: some View {
        HStack(
            alignment: .top,
            spacing: 12
        ) {
            if let photoURL {
                thumbnail(url: photoURL)
            }

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

                // Если API не вернул taxon,
                // строка все равно остается понятной.
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

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        // Preview является декоративным элементом:
        // VoiceOver получает информацию из текста строки.
        .accessibilityElement(
            children: .combine
        )
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
        .frame(width: 88, height: 88)
        .clipShape(
            RoundedRectangle(cornerRadius: 12)
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