import Foundation

// Централизованная privacy-логика для местоположения observation.
// UI никогда не работает с точными координатами и получает
// только безопасное приблизительное описание места.
enum ObservationPrivacy {

    static func approximateLocation(
        for observation: Observation
    ) -> String? {
        guard !observation.obscured,
              !isRestricted(observation.geoprivacy),
              !isRestricted(observation.taxonGeoprivacy) else {
            return nil
        }

        return nonEmpty(observation.placeGuess)
    }

    private static func isRestricted(
        _ value: String?
    ) -> Bool {
        guard let value = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
              !value.isEmpty else {
            return false
        }

        return value == "private"
            || value == "obscured"
    }

    private static func nonEmpty(
        _ value: String?
    ) -> String? {
        guard let value = value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty else {
            return nil
        }

        return value
    }
}