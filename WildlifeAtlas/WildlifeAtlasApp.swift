import SwiftUI

// Точка входа в приложение.
// SwiftUI создает основное окно и показывает ContentView,
// который является корневым экраном Wildlife Atlas.
@main
struct WildlifeAtlasApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}