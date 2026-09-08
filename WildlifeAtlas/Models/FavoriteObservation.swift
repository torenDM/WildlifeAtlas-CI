import Foundation

// Компактный snapshot observation для локальных закладок.
// Храним только информацию, необходимую для списка Favorites.
// Данные о местоположении намеренно не сохраняются.
struct FavoriteObservation: Codable, Identifiable, Equatable {
    let id: Int
    let commonName: String?
    let scientificName: String?
    let observedOn: String?
    let qualityGrade: String
    let photoURL: String?

    init(observation: Observation) {
        id = observation.id

        commonName = Self.nonEmpty(
            observation.taxon?.preferredCommonName
        )

        scientificName = Self.nonEmpty(
            observation.taxon?.name
        )

        observedOn = Self.nonEmpty(
            observation.observedOn
        )

        qualityGrade = observation.qualityGrade

        photoURL = observation.photos.first.flatMap {
            Self.preferredPhotoURL($0)
        }
    }

    private static func preferredPhotoURL(
        _ photo: INaturalistPhoto
    ) -> String? {
        let candidates = [
            photo.mediumUrl,
            photo.squareUrl,
            photo.url
        ]

        for candidate in candidates {
            if let value = nonEmpty(candidate) {
                return value
            }
        }

        return nil
    }

    private static func nonEmpty(
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