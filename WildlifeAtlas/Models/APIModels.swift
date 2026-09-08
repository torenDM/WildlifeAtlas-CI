import Foundation

// Универсальная обертка ответа iNaturalist API.
// Используется для списков наблюдений, результатов поиска таксонов
// и получения конкретного наблюдения.
struct APIResponse<T: Decodable>: Decodable {
    let totalResults: Int
    let page: Int
    let perPage: Int
    let results: [T]
}

// Основная DTO-модель наблюдения из iNaturalist.
// Многие поля Optional, так как API может не вернуть часть информации.
// В UI такие отсутствующие данные просто не отображаются.
struct Observation: Decodable, Identifiable {
    let id: Int
    let qualityGrade: String

    // Данные о времени и пользовательском определении наблюдения.
    let timeObservedAt: String?
    let observedOn: String?
    let speciesGuess: String?

    let captive: Bool

    // Связанные сущности наблюдения.
    let taxon: Taxon?
    let photos: [INaturalistPhoto]
    let user: ObservationUser?

    // Данные о местоположении.
    // В интерфейсе используем только приблизительное placeGuess
    // и учитываем настройки приватности наблюдения.
    let placeGuess: String?
    let obscured: Bool
    let geoprivacy: String?
    let taxonGeoprivacy: String?

    // Дополнительная информация для экрана деталей и Share.
    let uri: String?
    let description: String?
}

// Таксон, к которому относится наблюдение.
// Эта же модель используется в результатах taxon autocomplete.
struct Taxon: Decodable, Identifiable {
    let id: Int
    let name: String

    let rank: String?
    let preferredCommonName: String?
    let iconicTaxonName: String?

    let defaultPhoto: INaturalistPhoto?

    // Предки таксона нужны для построения таксономии
    // на экране подробной информации.
    let ancestors: [TaxonAncestor]?
}

// Упрощенная модель родительского таксона.
// Содержит только данные, необходимые для отображения taxonomy.
struct TaxonAncestor: Decodable, Identifiable {
    let id: Int
    let name: String

    let rank: String?
    let preferredCommonName: String?
}

// Фотография наблюдения или таксона.
// API предоставляет несколько размеров изображения,
// что позволяет выбирать подходящий вариант для списка и деталей.
struct INaturalistPhoto: Decodable, Identifiable {
    let id: Int

    // Лицензионная информация отображается на экране деталей.
    let licenseCode: String?
    let attribution: String?
    let attributionName: String?

    let url: String?
    let squareUrl: String?
    let mediumUrl: String?

    let originalDimensions: PhotoDimensions?
}

// Исходный размер фотографии.
// Может пригодиться при отображении полноразмерной галереи.
struct PhotoDimensions: Decodable {
    let width: Int
    let height: Int
}

// Пользователь iNaturalist, создавший наблюдение.
// Используется прежде всего на экране деталей.
struct ObservationUser: Decodable, Identifiable {
    let id: Int
    let login: String

    let name: String?
    let iconUrl: String?
}