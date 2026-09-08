# Wildlife Atlas
Wildlife Atlas — iOS-приложение для просмотра наблюдений за живой природой из iNaturalist.
Приложение разработано на Swift и SwiftUI в рамках тестового задания на стажировку.

## Возможности
### Explore
Основной экран отображает список наблюдений из iNaturalist API.
Для каждого наблюдения отображаются:
- фотография;
- common name;
- scientific name;
- дата наблюдения;
- quality grade.
Поддерживаются два режима отображения:
- List;
- Grid.
Переключение между ними не приводит к повторной загрузке данных.

### Пагинация
Наблюдения загружаются постранично.
Следующая страница запрашивается при достижении конца текущего списка.
При ошибке загрузки следующей страницы уже загруженные данные остаются на экране, а пользователь может повторить запрос отдельно.

### Фильтры
Поддерживаются три независимых фильтра:
- Taxon;
- Quality:
  - Any;
  - Research;
- Order:
  - Newest first;
  - Oldest first.

Сортировка выполняется именно по дате наблюдения:
`order_by=observed_on`
При изменении любого фильтра список перезагружается с первой страницы.
Для всех запросов наблюдений используется обязательный параметр:
`captive=false`

### Taxon autocomplete
Выбор таксона реализован через iNaturalist endpoint autocomplete.
Поддерживаются:
- поиск по common name и scientific name;
- debounce перед отправкой запроса;
- отмена устаревших async-запросов;
- хранение последних 5 выбранных таксонов.
Недавние таксоны сохраняются локально через `UserDefaults`.

## Observation Details
При выборе наблюдения открывается отдельный экран деталей.
Данные наблюдения повторно загружаются по его ID через iNaturalist API.
Отображаются:
- все доступные фотографии;
- common name;
- scientific name;
- quality grade;
- дата наблюдения;
- автор;
- taxonomy;
- attribution фотографии;
- license;
- приблизительное местоположение.

### Privacy
Приложение намеренно не отображает точные координаты наблюдений.
Не используются:
- `location`;
- `geojson.coordinates`.
Для отображения местоположения используется только `place_guess`.
Если наблюдение имеет признаки private или obscured location, местоположение не показывается.

## Gallery и Share
Все доступные фотографии observation отображаются в gallery.
Поддерживается системный Share через URL наблюдения iNaturalist.

## Favorites
Наблюдение можно добавить в локальные закладки.
Favorites:
- сохраняются через `UserDefaults`;
- доступны в отдельном разделе;
- не требуют отдельного API-запроса для построения списка;
- позволяют открыть актуальные Details выбранного observation;
- поддерживают удаление из списка и через кнопку на экране Details.
Для локального хранения используется компактный snapshot модели наблюдения.

## Image Cache
Для изображений реализован memory cache на основе `NSCache`.
Один и тот же image URL повторно используется между:
- List;
- Grid;
- Details;
- Favorites.
Это уменьшает количество повторных сетевых запросов при навигации между экранами.

## Состояния экранов
Для основных экранов предусмотрены состояния:
- loading;
- content;
- empty;
- error;
- retry.
Состояние загрузки следующей страницы хранится отдельно от общего состояния Explore, поэтому ошибка пагинации не скрывает уже загруженный контент.

## Сохранение состояния Explore
`ExploreViewModel` создается как `@StateObject` корневого `ContentView`.
Переход к Details выполняется внутри `NavigationStack`, поэтому при возврате не создается новый экземпляр Explore ViewModel и не выполняется повторная загрузка первой страницы.
Таким образом сохраняются:
- уже загруженные observations;
- активные фильтры;
- выбранный taxon;
- режим List/Grid;
- состояние текущего Explore-экрана.

## Архитектура
В проекте используется MVVM.
Основной поток данных:
```text
View
  ↓
ViewModel
  ↓
INaturalistService
  ↓
APIClient
  ↓
URLSession
```

### View
Отвечает за:
- SwiftUI-разметку;
- navigation;
- presentation state;
- отображение состояния ViewModel.

### ViewModel
Отвечает за:
- загрузку данных;
- состояния экрана;
- фильтрацию;
- пагинацию;
- обработку ошибок;
- защиту от устаревших async-ответов.

### INaturalistService
Содержит знания о конкретных iNaturalist endpoint'ах и query parameters.
Сервис реализует `INaturalistServiceProtocol`, благодаря чему его можно заменить mock-реализацией в unit-тестах.

### APIClient
Отвечает за:
- `URLSession`;
- HTTP status codes;
- декодирование JSON;
- преобразование networking-ошибок.

## Используемые технологии
- Swift
- SwiftUI
- MVVM
- async/await
- Codable
- URLSession
- Combine
- UserDefaults
- NSCache
- XCTest
- Swift Package Manager
- GitHub Actions
Сторонние библиотеки не используются.

## API
Используется:
```text
https://api.inaturalist.org/v1
```
Основные endpoint'ы:
```text
GET /observations
GET /observations/{id}
GET /taxa/autocomplete
```

## Unit Tests
Для тестирования networking-зависимость ViewModel вынесена в:
```swift
INaturalistServiceProtocol
```
В тестах используется mock-сервис вместо реального API.
Проверяется в том числе:
- successful initial loading;
- empty response;
- error state;
- независимость фильтров;
- reload первой страницы после изменения фильтра;
- pagination;
- исключение duplicate observation ID;
- загрузка Details по ID;
- privacy rules;
- сохранение Favorites через `UserDefaults`.
Core-тесты запускаются через:
```bash
swift test
```
## CI
В репозитории используются две независимые GitHub Actions проверки.

### iOS Build
Приложение собирается через `xcodebuild` на macOS runner с iPhone Simulator SDK.

### Unit Tests
Бизнес-логика проверяется через:
```bash
swift test
```
Перед отправкой изменений в основной репозиторий код проверялся в отдельном CI-репозитории.

## Запуск проекта
Требуется:
- macOS;
- Xcode с поддержкой iOS 17 или новее.
1. Клонировать репозиторий.
2. Открыть:
```text
WildlifeAtlas.xcodeproj
```
3. Выбрать iPhone Simulator.
4. Запустить target:
```text
WildlifeAtlas
```
5. Нажать Run.
Дополнительные зависимости устанавливать не требуется.

## Особенности разработки
Основная разработка выполнялась в Windows-среде без локального Xcode.
Поэтому Swift-код, не зависящий от iOS runtime, дополнительно проверялся локально, а полноценная сборка приложения выполнялась через GitHub Actions на macOS/Xcode.
Файл:
```text
WildlifeAtlas.xcodeproj/project.pbxproj
```
редактировался вручную при добавлении новых Swift-файлов в проект.

## Структура проекта
```text
WildlifeAtlas/
├── Models/
│   ├── APIModels.swift
│   ├── TaxonSelection.swift
│   ├── ObservationPrivacy.swift
│   └── FavoriteObservation.swift
│
├── Networking/
│   ├── APIClient.swift
│   ├── APIError.swift
│   ├── ObservationFilters.swift
│   └── INaturalistService.swift
│
├── ViewModels/
│   ├── ExploreViewModel.swift
│   ├── TaxonSearchViewModel.swift
│   ├── ObservationDetailViewModel.swift
│   └── FavoritesStore.swift
│
├── Views/
│   ├── ObservationRowView.swift
│   ├── ObservationGridItemView.swift
│   ├── ObservationDetailView.swift
│   ├── TaxonSearchView.swift
│   ├── FavoritesView.swift
│   ├── CachedAsyncImage.swift
│   └── ObservationPresentation.swift
│
├── ContentView.swift
└── WildlifeAtlasApp.swift

Tests/
└── WildlifeAtlasCoreTests/

Package.swift
README.md
AI_USAGE.md
```

## AI usage
При разработке использовался ChatGPT, а также Gemini для его перепроверки.
Подробное описание способов использования AI, ключевых промптов, созданных с его помощью частей решения и отклоненных предложений приведено в:
```text
AI_USAGE.md
```