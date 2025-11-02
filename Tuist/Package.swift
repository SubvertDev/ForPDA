// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Default is .staticFramework
        productTypes: [
            "CasePaths": .framework,
            "CasePathsCore": .framework,
            "Clocks": .framework,
            "CombineSchedulers": .framework,
            "ComposableArchitecture": .framework,
            "ConcurrencyExtras": .framework,
            "CustomDump": .framework,
            "Dependencies": .framework,
            "DependenciesMacros": .framework,
            "IdentifiedCollections": .framework,
            "IssueReporting": .framework,
            "OrderedCollections": .framework,
            "Perception": .framework,
            "PerceptionCore": .framework,
            "Sharing": .framework,
            "Sharing1": .framework,
            "Sharing2": .framework,
            "SwiftNavigation": .framework,
            "SwiftUINavigation": .framework,
            "UIKitNavigation": .framework,
            "UIKitNavigationShim": .framework,
            "XCTestDynamicOverlay": .framework,
            
            "Nuke": .framework,
            "NukeUI": .framework,
            "RichTextKit": .framework,
            "SkeletonUI": .framework,
            "SFSafeSymbols": .framework,
            
            "YouTubePlayerKit": .framework
        ]
    )
#endif

let package = Package(
    name: "ForPDA",
    dependencies: [
        // TCA
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.23.1"),
        
        // TCA Dependencies
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.4"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", from: "1.0.6"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", from: "1.3.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.3"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.10.0"),
        .package(url: "https://github.com/pointfreeco/swift-navigation", from: "2.6.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", from: "2.0.9"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", from: "2.7.4"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", from: "1.18.7"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", from: "1.7.0"),
        // Other
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", from: "7.0.0"),
        .package(url: "https://github.com/hyperoslo/Cache.git", from: "7.4.0"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.8.0"),
        .package(url: "https://github.com/PostHog/posthog-ios.git", exact: "3.34.0"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", exact: "8.57.1"),
        .package(url: "https://github.com/CSolanaM/SkeletonUI.git", from: "2.0.2"),
        .package(url: "https://github.com/raymondjavaxx/SmoothGradient.git", branch: "main"),
        .package(url: "https://github.com/SvenTiigi/YouTubePlayerKit.git", from: "2.0.4"),
        .package(url: "https://github.com/SubvertDev/AlertToast.git", revision: "d0f7d6b"),
        .package(url: "https://github.com/kirualex/SwiftyGif.git", from: "5.4.4"),
        .package(url: "https://github.com/ZhgChgLi/ZMarkupParser.git", from: "1.12.0"),
        .package(url: "https://github.com/SubvertDev/PDAPI_SPM.git", exact: "0.6.0"),
        .package(url: "https://github.com/SubvertDev/RichTextKit.git", branch: "main"),
        .package(url: "https://github.com/exyte/Chat.git", exact: "2.4.2"), // 2.5.0+ is iOS 17+
        .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro.git", from: "0.5.2")
    ]
)
