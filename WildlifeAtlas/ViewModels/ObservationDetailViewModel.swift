import Foundation
import Combine

// ViewModel экрана деталей observation.
// Загружает актуальное наблюдение по ID и изолирует View
// от networking-слоя и обработки ошибок.
@MainActor
final class ObservationDetailViewModel: ObservableObject {

    enum State {
        case loading
        case content
        case empty
        case error(String)
    }

    @Published private(set) var state: State = .loading
    @Published private(set) var observation: Observation?

    private let service: INaturalistService

    // Не загружаем одно и то же observation повторно
    // при повторных вызовах SwiftUI task.
    private var didLoadObservation = false

    init(
        service: INaturalistService = INaturalistService()
    ) {
        self.service = service
    }

    func loadIfNeeded(
        id: Int
    ) async {
        guard !didLoadObservation else {
            return
        }

        didLoadObservation = true

        await load(
            id: id,
            resetLoadFlagOnCancellation: true
        )
    }

    func retry(
        id: Int
    ) async {
        await load(id: id)
    }

    private func load(
        id: Int,
        resetLoadFlagOnCancellation: Bool = false
    ) async {
        state = .loading
        observation = nil

        do {
            let observation = try await service.observation(
                id: id
            )

            self.observation = observation
            state = .content

        } catch is CancellationError {
            if resetLoadFlagOnCancellation {
                didLoadObservation = false
            }

        } catch let error as APIError {
            observation = nil

            if case .invalidResponse = error {
                state = .empty
            } else {
                state = .error(error.localizedDescription)
            }

        } catch {
            observation = nil
            state = .error(error.localizedDescription)
        }
    }
}