# ForPDA
![Лого](logo.png)  
Альтернативный клиент [4pda.to](https://4pda.to/)

![Скриншоты](screenshots/5-screenshots.png)

## Требования и установка
- iOS 14.0+ / macOS 13.0+
- Xcode 14.3+ / Swift 5.8+
- Скачать и запустить проект, зависимости загрузятся автоматически через SPM
- Создать Secrets.xcconfig и ввести значения для ключей SENTRY_DSN, SENTRY_DSYM_TOKEN, AMPLITUDE_TOKEN, TELEGRAM_TOKEN, TELEGRAM_CHAT_ID

## Используемые иблиотеки
- [Amplitude](https://github.com/amplitude/Amplitude-Swift) - аналитика
- [Sentry](https://github.com/getsentry/sentry-cocoa) - мониторинг ошибок
- [SwiftSoup](https://github.com/scinfu/SwiftSoup) - парсинг HTML страниц
- [SwitchRichString](https://github.com/malcommac/SwiftRichString) - преобразование HTML строк в TextView
- [RouteComposer](https://github.com/ekazaev/route-composer) - навигация
- [Rswift](https://github.com/mac-cain13/R.swift) - кодогенерация текста/картинок/шрифтов/цветов
- [Factory](https://github.com/hmlongco/Factory) - инъекция зависимостей
- [Nuke](https://github.com/kean/Nuke) - загрузка и кеширование изображений
- [SnapKit](https://github.com/SnapKit/SnapKit) - для упрощения работы с констреинтами
- [SwiftMessages](https://github.com/SwiftKickMobile/SwiftMessages) - всплывающие окна
- [SwipeCellKit](https://github.com/SwipeCellKit/SwipeCellKit) - отображение комментариев
- [SwiftyGif](https://github.com/kirualex/SwiftyGif) - отображение гифок
- [YouTubePlayerKit](https://github.com/SvenTiigi/YouTubePlayerKit) - отображение видео с YouTube
- [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols) - type safe SF символы

## Благодарности
- [Tatiana](https://github.com/tikh-hehe) - за помощь с доработкой функционала

## Лицензия
GPL v3 (C) 2022-2023 [Ilia Lubianoi](https://github.com/SubvertDev)
