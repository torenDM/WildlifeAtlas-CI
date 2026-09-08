import Foundation

// Текущее состояние фильтрации списка наблюдений.
// Каждый фильтр независим от остальных и передается
// в INaturalistService при загрузке любой страницы.
struct ObservationFilters {
    var taxonID: Int?
    var quality: QualityFilter = .any
    var order: ObservationOrder = .newest
}

// Доступные варианты фильтра качества.
// Any означает отсутствие quality_grade в API-запросе.
enum QualityFilter: String {
    case any
    case research

    var apiValue: String? {
        switch self {
        case .any:
            return nil

        case .research:
            return "research"
        }
    }
}

// Порядок наблюдений определяется именно датой наблюдения,
// а не датой создания записи в iNaturalist.
enum ObservationOrder: String {
    case newest
    case oldest

    var apiValue: String {
        switch self {
        case .newest:
            return "desc"

        case .oldest:
            return "asc"
        }
    }
}