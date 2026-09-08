import Foundation

// Небольшая domain-модель выбранного таксона.
// В отличие от полного Taxon содержит только данные,
// необходимые фильтру и истории последних выборов.
struct TaxonSelection: Codable, Identifiable, Equatable {
    let id: Int
    let scientificName: String
    let commonName: String?

    init(
        id: Int,
        scientificName: String,
        commonName: String?
    ) {
        self.id = id
        self.scientificName = scientificName
        self.commonName = commonName
    }

    // Преобразуем DTO из API в компактную модель,
    // которую можно безопасно сохранить локально.
    init(taxon: Taxon) {
        self.id = taxon.id
        self.scientificName = taxon.name

        let commonName = taxon.preferredCommonName?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        self.commonName = {
            guard let commonName,
                  !commonName.isEmpty else {
                return nil
            }

            return commonName
        }()
    }

    var displayName: String {
        commonName ?? scientificName
    }
}