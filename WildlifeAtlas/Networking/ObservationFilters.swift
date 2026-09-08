import Foundation

struct ObservationFilters {
    var taxonID: Int?
    var quality: QualityFilter = .any
    var order: ObservationOrder = .newest
}

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