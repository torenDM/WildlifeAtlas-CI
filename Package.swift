// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "WildlifeAtlasCore",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "WildlifeAtlasCore",
            targets: ["WildlifeAtlasCore"]
        )
    ],
    targets: [
        .target(
            name: "WildlifeAtlasCore",
            path: "WildlifeAtlas",
            sources: [
                "Models/APIModels.swift",
                "Models/TaxonSelection.swift",
                "Models/ObservationPrivacy.swift",
                "Models/FavoriteObservation.swift",

                "Networking/APIClient.swift",
                "Networking/APIError.swift",
                "Networking/ObservationFilters.swift",
                "Networking/INaturalistService.swift",

                "ViewModels/ExploreViewModel.swift",
                "ViewModels/TaxonSearchViewModel.swift",
                "ViewModels/ObservationDetailViewModel.swift",
                "ViewModels/FavoritesStore.swift"
            ]
        ),
        .testTarget(
            name: "WildlifeAtlasCoreTests",
            dependencies: [
                "WildlifeAtlasCore"
            ],
            path: "Tests/WildlifeAtlasCoreTests"
        )
    ],
    swiftLanguageVersions: [.v5]
)