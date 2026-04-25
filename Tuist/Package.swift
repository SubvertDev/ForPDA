// swift-tools-version: 6.2
import PackageDescription

#if TUIST
    import ProjectDescription

    let packageSettings = PackageSettings(
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
            "SwiftyGif": .framework,
            
            "YouTubePlayerKit": .framework
        ],
        targetSettings: [
            "ComposableArchitecture": .settings(
                base: .moduleAliasForSharing,
                defaultSettings: .recommended
            ),
            "Sharing": .settings(
                base: .moduleAliasForSharing.merging(.productNameForSharing),
                defaultSettings: .recommended
            )
        ]
    )
extension SettingsDictionary {
    static let moduleAliasForSharing = SettingsDictionary()
        .otherSwiftFlags(["-module-alias", "Sharing=PFSharing"])
    
    static let productNameForSharing = SettingsDictionary()
        .merging(["PRODUCT_NAME": "PFSharing"])
}
#endif

let package = Package(
    name: "ForPDA",
    dependencies: [
        // TCA
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture.git", from: "1.25.5"),
                
        // TCA Dependencies
        .package(url: "https://github.com/apple/swift-async-algorithms", exact: "1.1.3"),
        .package(url: "https://github.com/pointfreeco/swift-clocks", exact: "1.0.6"),
        .package(url: "https://github.com/pointfreeco/swift-concurrency-extras", exact: "1.3.2"),
        .package(url: "https://github.com/pointfreeco/swift-custom-dump", exact: "1.4.1"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", exact: "1.12.0"),
        .package(url: "https://github.com/pointfreeco/swift-navigation", exact: "2.8.0"),
        .package(url: "https://github.com/pointfreeco/swift-perception", exact: "2.0.10"),
        .package(url: "https://github.com/pointfreeco/swift-sharing", exact: "2.8.0"),
        .package(url: "https://github.com/pointfreeco/swift-snapshot-testing", exact: "1.19.2"),
        .package(url: "https://github.com/pointfreeco/xctest-dynamic-overlay", exact: "1.9.0"),

        // Other
        .package(url: "https://github.com/CSolanaM/SkeletonUI", exact: "2.0.2"),
        .package(url: "https://github.com/getsentry/sentry-cocoa", exact: "9.11.0"),
        .package(url: "https://github.com/gohanlon/swift-memberwise-init-macro", exact: "0.5.2"),
        .package(url: "https://github.com/hyperoslo/Cache", exact: "7.4.0"),
        .package(url: "https://github.com/kean/Nuke", exact: "12.8.0"),
        .package(url: "https://github.com/kirualex/SwiftyGif", exact: "5.4.5"),
        .package(url: "https://github.com/PostHog/posthog-ios", exact: "3.57.0"),
        .package(url: "https://github.com/raymondjavaxx/SmoothGradient.git", exact: "1.0.1"),
        .package(url: "https://github.com/SFSafeSymbols/SFSafeSymbols", exact: "7.0.0"),
        .package(url: "https://github.com/SvenTiigi/YouTubePlayerKit", exact: "2.0.5"),
        .package(url: "https://github.com/ZhgChgLi/ZMarkupParser", exact: "1.12.0"),

        // Forks & stuff
        .package(url: "https://github.com/SubvertDev/AlertToast.git", revision: "d0f7d6b"),
        .package(url: "https://github.com/SubvertDev/Chat", branch: "main"),
        .package(url: "https://github.com/SubvertDev/PDAPI_SPM.git", exact: "0.8.0"),
        .package(url: "https://github.com/SubvertDev/RichTextKit.git", branch: "main"),
    ]
)
