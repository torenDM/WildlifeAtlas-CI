import Foundation

// Общие правила отображения данных observation.
// API-модели сохраняют исходные значения,
// а форматирование выполняется только на presentation-слое.
enum ObservationPresentation {

    static func nonEmpty(
        _ value: String?
    ) -> String? {
        guard
            let value = value?
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                ),
            !value.isEmpty
        else {
            return nil
        }

        return value
    }

    static func qualityTitle(
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

    // observed_on обычно приходит как yyyy-MM-dd.
    // Если API однажды вернет неожиданное значение,
    // показываем его как есть вместо потери информации.
    static func observedDate(
        _ value: String?
    ) -> String? {
        guard let value = nonEmpty(value) else {
            return nil
        }

        guard let date = inputDateFormatter.date(
            from: value
        ) else {
            return value
        }

        return outputDateFormatter.string(
            from: date
        )
    }

    private static let inputDateFormatter:
        DateFormatter = {
            let formatter = DateFormatter()

            formatter.locale = Locale(
                identifier: "en_US_POSIX"
            )

            formatter.calendar = Calendar(
                identifier: .gregorian
            )

            formatter.timeZone = TimeZone(
                secondsFromGMT: 0
            )

            formatter.dateFormat = "yyyy-MM-dd"

            return formatter
        }()

    private static let outputDateFormatter:
        DateFormatter = {
            let formatter = DateFormatter()

            formatter.locale = .current
            formatter.dateStyle = .medium
            formatter.timeStyle = .none

            return formatter
        }()
}