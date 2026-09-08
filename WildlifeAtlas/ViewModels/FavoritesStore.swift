import Foundation
import Combine

// Общее состояние локальных закладок.
// Store создается один раз в ContentView и передается
// дочерним экранам через SwiftUI Environment.
@MainActor
final class FavoritesStore: ObservableObject {

    @Published private(set) var favorites:
        [FavoriteObservation] = []

    private let userDefaults: UserDefaults
    private let storageKey = "favoriteObservations"

    init(
        userDefaults: UserDefaults = .standard
    ) {
        self.userDefaults = userDefaults
        load()
    }

    func contains(
        id: Int
    ) -> Bool {
        favorites.contains {
            $0.id == id
        }
    }

    func toggle(
        _ observation: Observation
    ) {
        if contains(id: observation.id) {
            remove(id: observation.id)
            return
        }

        let favorite = FavoriteObservation(
            observation: observation
        )

        favorites.insert(
            favorite,
            at: 0
        )

        save()
    }

    func remove(
        id: Int
    ) {
        favorites.removeAll {
            $0.id == id
        }

        save()
    }

    func remove(
        at offsets: IndexSet
    ) {
        for index in offsets.sorted(by: >) {
            guard favorites.indices.contains(index) else {
                continue
            }

            favorites.remove(at: index)
        }

        save()
    }

    private func load() {
        guard
            let data = userDefaults.data(
                forKey: storageKey
            ),
            let storedFavorites =
                try? JSONDecoder().decode(
                    [FavoriteObservation].self,
                    from: data
                )
        else {
            return
        }

        favorites = storedFavorites
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(
            favorites
        ) else {
            return
        }

        userDefaults.set(
            data,
            forKey: storageKey
        )
    }
}