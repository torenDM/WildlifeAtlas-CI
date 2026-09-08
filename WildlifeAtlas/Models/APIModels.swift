import Foundation

struct APIResponse<T: Decodable>: Decodable {
    let totalResults: Int
    let page: Int
    let perPage: Int
    let results: [T]
}

struct Observation: Decodable, Identifiable {
    let id: Int
    let qualityGrade: String

    let timeObservedAt: String?
    let observedOn: String?
    let speciesGuess: String?

    let captive: Bool

    let taxon: Taxon?
    let photos: [INaturalistPhoto]
    let user: ObservationUser?

    let placeGuess: String?
    let obscured: Bool
    let geoprivacy: String?
    let taxonGeoprivacy: String?

    let uri: String?
    let description: String?
}

struct Taxon: Decodable, Identifiable {
    let id: Int
    let name: String

    let rank: String?
    let preferredCommonName: String?
    let iconicTaxonName: String?

    let defaultPhoto: INaturalistPhoto?
    let ancestors: [TaxonAncestor]?
}

struct TaxonAncestor: Decodable, Identifiable {
    let id: Int
    let name: String

    let rank: String?
    let preferredCommonName: String?
}

struct INaturalistPhoto: Decodable, Identifiable {
    let id: Int

    let licenseCode: String?
    let attribution: String?
    let attributionName: String?

    let url: String?
    let squareUrl: String?
    let mediumUrl: String?

    let originalDimensions: PhotoDimensions?
}

struct PhotoDimensions: Decodable {
    let width: Int
    let height: Int
}

struct ObservationUser: Decodable, Identifiable {
    let id: Int
    let login: String

    let name: String?
    let iconUrl: String?
}