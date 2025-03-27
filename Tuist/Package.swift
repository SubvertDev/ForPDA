// swift-tools-version: 6.0
@preconcurrency import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        // Default is .staticFramework
        productTypes: [
            "_CollectionsUtilities": .framework,
            "CasePaths": .framework,
            "Clocks": .framework,
            "ComposableArchitecture": .framework,
            "ConcurrencyExtras": .framework,
            "CombineSchedulers": .framework,
            "CustomDump": .framework,
            "Dependencies": .framework,
            "DependenciesMacros": .framework,
            "IdentifiedCollections": .framework,
            "IssueReporting": .framework,
            "OrderedCollections": .framework,
            "Perception": .framework,
            "PerceptionCore": .framework,
            "SwiftUINavigationCore": .framework,
            "XCTestDynamicOverlay": .framework,
            
            "Nuke": .framework,
            "NukeUI": .framework,
            "RichTextKit": .framework,
            "SkeletonUI": .framework,
            "SFSafeSymbols": .framework
        ]
    )
#endif

let package = Package(
    name: "ForPDA",
    dependencies: [
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.17.0"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols.git", from: "5.3.0"),
        .package(url: "https://github.com/hyperoslo/Cache.git", from: "7.3.0"),
        .package(url: "https://github.com/kean/Nuke.git", from: "12.8.0"),
        .package(url: "https://github.com/PostHog/posthog-ios", from: "3.20.1"),
        .package(url: "https://github.com/getsentry/sentry-cocoa.git", from: "8.48.0"),
        .package(url: "https://github.com/CSolanaM/SkeletonUI.git", from: "2.0.2"),
        .package(url: "https://github.com/raymondjavaxx/SmoothGradient.git", branch: "main"),
        .package(url: "https://github.com/SvenTiigi/YouTubePlayerKit.git", from: "1.9.0"),
        .package(url: "https://github.com/SubvertDev/AlertToast.git", revision: "d0f7d6b"),
        .package(url: "https://github.com/kirualex/SwiftyGif.git", from: "5.4.4"),
        .package(url: "https://github.com/ZhgChgLi/ZMarkupParser.git", from: "1.12.0"),
        .package(url: "https://github.com/SubvertDev/PDAPI_SPM.git", from: "0.3.0"),
        .package(url: "https://github.com/SubvertDev/RichTextKit.git", branch: "main"),
        .package(url: "https://github.com/exyte/Chat.git", from: "2.0.10"),
        .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro", from: "0.5.1")
    ]
)
