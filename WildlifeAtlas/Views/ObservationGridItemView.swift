import SwiftUI

struct ObservationGridItemView: View {
    let observation: Observation

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let photoURL {
                AsyncImage(url: photoURL) { phase in
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

                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
                .accessibilityLabel("Observation photo")
            }

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

            if let observedOn {
                Label(observedOn, systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Text(qualityTitle)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.quaternary)
                .clipShape(Capsule())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            .thinMaterial,
            in: RoundedRectangle(cornerRadius: 14)
        )
    }

    private var photoURL: URL? {
        guard let photo = observation.photos.first else {
            return nil
        }

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

    private var commonName: String? {
        nonEmpty(observation.taxon?.preferredCommonName)
    }

    private var scientificName: String? {
        nonEmpty(observation.taxon?.name)
    }

    private var observedOn: String? {
        nonEmpty(observation.observedOn)
    }

    private var qualityTitle: String {
        switch observation.qualityGrade {
        case "research":
            return "Research"

        case "needs_id":
            return "Needs ID"

        case "casual":
            return "Casual"

        default:
            return observation.qualityGrade
                .replacingOccurrences(of: "_", with: " ")
                .capitalized
        }
    }

    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}