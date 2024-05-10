// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ForPDA",
    platforms: [.iOS(.v16)],
    products: [
        // Features
        .library(name: "AppFeature", targets: ["AppFeature"]),
        .library(name: "NewsListFeature", targets: ["NewsListFeature"]),
        .library(name: "NewsFeature", targets: ["NewsFeature"]),
        .library(name: "MenuFeature", targets: ["MenuFeature"]),
        
        // Clients
        .library(name: "NewsClient", targets: ["NewsClient"]),
        .library(name: "SettingsClient", targets: ["SettingsClient"]),
        .library(name: "ParsingClient", targets: ["ParsingClient"]),
        
        // Misc
        .library(name: "Models", targets: ["Models"])
    ],
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.10.3"),
        .package(url: "https://github.com/hmlongco/Factory", from: "2.3.2"),
        .package(url: "https://github.com/scinfu/SwiftSoup", from: "2.7.2"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", from: "5.2.0"),
        .package(url: "https://github.com/kean/Nuke", from: "12.6.0"),
        .package(url: "https://github.com/mixpanel/mixpanel-swift", from: "4.2.7"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.25.2"),
        .package(url: "https://github.com/SvenTiigi/YouTubePlayerKit", from: "1.8.0")
    ],
    targets: [
        
        // MARK: - Features
        
        .target(
            name: "AppFeature",
            dependencies: [
                "NewsListFeature",
                "NewsFeature",
                "MenuFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Mixpanel", package: "mixpanel-swift"),
                .product(name: "Sentry", package: "sentry-cocoa")
            ]
        ),
        .target(
            name: "NewsListFeature",
            dependencies: [
                "Models",
                "NewsClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "NukeUI", package: "nuke")
            ]
        ),
        .target(
            name: "NewsFeature",
            dependencies: [
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        .target(
            name: "MenuFeature",
            dependencies: [
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        ),
        
        // MARK: - Clients
        
        .target(
            name: "NewsClient",
            dependencies: [
                "SettingsClient",
                "ParsingClient",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "Factory", package: "Factory")
            ]
        ),
        .target(
            name: "SettingsClient",
            dependencies: [
                "Models"
            ]
        ),
        .target(
            name: "ParsingClient",
            dependencies: [
                "Models",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "SwiftSoup", package: "SwiftSoup")
            ]
        ),
        
        // MARK: - Helpers
        
        .target(
            name: "Models",
            dependencies: [
                .product(name: "SFSafeSymbols", package: "SFSafeSymbols")
            ]
        ),
        
        // MARK: - Tests
        
        .testTarget(
            name: "AppFeatureTests",
            dependencies: [
                "AppFeature",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture")
            ]
        )
    ]
)
