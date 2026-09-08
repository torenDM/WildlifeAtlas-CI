import Foundation
import SwiftUI
import UIKit

// Простой memory-only cache изображений.
// NSCache автоматически освобождает объекты при давлении на память,
// поэтому изображения не сохраняются на диск.
@MainActor
final class MemoryImageCache {

    static let shared = MemoryImageCache()

    private let cache = NSCache<NSURL, UIImage>()

    private init() {
        // Ограничиваем приблизительный объём кэша,
        // чтобы большое количество фотографий не удерживалось бесконечно.
        cache.totalCostLimit = 50 * 1024 * 1024
    }

    func image(
        for url: URL
    ) -> UIImage? {
        cache.object(
            forKey: url as NSURL
        )
    }

    func insert(
        _ image: UIImage,
        for url: URL
    ) {
        let cost: Int

        if let cgImage = image.cgImage {
            cost = cgImage.bytesPerRow
                * cgImage.height
        } else {
            cost = 0
        }

        cache.setObject(
            image,
            forKey: url as NSURL,
            cost: cost
        )
    }
}

// Собственный аналог нужной нам части AsyncImagePhase.
enum CachedImagePhase {
    case empty
    case success(Image)
    case failure
}

// SwiftUI-компонент для загрузки удалённой картинки.
// Сначала проверяет memory cache и только при промахе
// выполняет URLSession-запрос.
struct CachedAsyncImage<Content: View>: View {

    let url: URL

    private let content:
        (CachedImagePhase) -> Content

    @State private var phase:
        CachedImagePhase = .empty

    init(
        url: URL,
        @ViewBuilder content:
            @escaping (CachedImagePhase) -> Content
    ) {
        self.url = url
        self.content = content
    }

    var body: some View {
        content(phase)
            .task(id: url) {
                await load()
            }
    }

    @MainActor
    private func load() async {
        if let cachedImage =
            MemoryImageCache.shared.image(
                for: url
            ) {
            phase = .success(
                Image(uiImage: cachedImage)
            )
            return
        }

        phase = .empty

        do {
            let (data, response) =
                try await URLSession.shared.data(
                    from: url
                )

            guard !Task.isCancelled else {
                return
            }

            guard
                let httpResponse =
                    response as? HTTPURLResponse,
                (200...299).contains(
                    httpResponse.statusCode
                ),
                let image = UIImage(data: data)
            else {
                phase = .failure
                return
            }

            MemoryImageCache.shared.insert(
                image,
                for: url
            )

            phase = .success(
                Image(uiImage: image)
            )

        } catch is CancellationError {
            return

        } catch {
            guard !Task.isCancelled else {
                return
            }

            phase = .failure
        }
    }
}