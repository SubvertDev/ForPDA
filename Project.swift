import ProjectDescription

let project = Project(
    name: "ForPDA",
    settings: .settings(
        base: SettingsDictionary()
            .swiftVersion("6.0")
            .debugInformationFormat(.dwarfWithDsym) // Disable for Debug?
            .otherSwiftFlags([
                "-Xfrontend",
                "-warn-long-function-bodies=600",
                "-Xfrontend",
                "-warn-long-expression-type-checking=100"
            ])
            .manualCodeSigning(
                identity: "iPhone Developer",
                provisioningProfileSpecifier: "match Development com.subvert.forpda"
            )
            .merging([
                "INFOPLIST_KEY_CFBundleDisplayName": "\(App.name)",
                "SWIFT_EMIT_LOC_STRINGS": "YES",
                "LOCALIZATION_EXPORT_SUPPORTED": "YES",
                "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES",
                "DEVELOPMENT_TEAM[sdk=iphoneos*]": "7353CQCGQC", // Do I need it?
            ]),
        configurations: [
            .debug(name: "Debug", xcconfig: "Configs/App.xcconfig"),
            .release(name: "Release", xcconfig: "Configs/App.xcconfig"),
        ]
    ),
    targets: [
        .target(
            name: App.name,
            destinations: .iOS,
            product: .app,
            bundleId: App.bundleId,
            deploymentTargets: .iOS("16.0"),
            infoPlist: .main,
            sources: ["Modules/App/**"],
            resources: ["Modules/Resources/**"],
            dependencies: [
                .target(name: "AppFeature")
            ],
            settings: .settings(
                base: [
                    // "OTHER_LDFLAGS": "$(inherited)",
                    "TARGETED_DEVICE_FAMILY": "1",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO"
                ]
            )
        ),
        
        // MARK: - Features
        
            .feature(
                name: "AppFeature",
                dependencies: [
                    .Internal.DeeplinkHandler,
                    .Internal.ArticlesListFeature,
                    .Internal.ArticleFeature,
                    .Internal.BookmarksFeature,
                    .Internal.ForumsListFeature,
                    .Internal.ForumFeature,
                    .Internal.TopicFeature,
                    .Internal.AnnouncementFeature,
                    .Internal.FavoritesRootFeature,
                    .Internal.BookmarksFeature,
                    .Internal.FavoritesFeature,
                    .Internal.HistoryFeature,
                    .Internal.AuthFeature,
                    .Internal.ProfileFeature,
                    .Internal.QMSListFeature,
                    .Internal.QMSFeature,
                    .Internal.SettingsFeature,
                    .Internal.NotificationsFeature,
                    .Internal.DeveloperFeature,
                    .Internal.NotificationsClient,
                    .Internal.AnalyticsClient,
                    .Internal.LoggerClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.TCAExtensions,
                    .SPM.AlertToast,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "DeeplinkHandler",
                hasResources: false,
                dependencies: [
                    .Internal.LoggerClient,
                    .Internal.AnalyticsClient,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ArticlesListFeature",
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.AnalyticsClient,
                    .Internal.PasteboardClient,
                    .Internal.HapticClient,
                    .Internal.TCAExtensions,
                    .Internal.PersistenceKeys,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ArticleFeature",
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .Internal.PasteboardClient,
                    .Internal.HapticClient,
                    .Internal.TCAExtensions,
                    .SPM.SkeletonUI,
                    .SPM.NukeUI,
                    .SPM.YouTubePlayerKit,
                    .SPM.SFSafeSymbols,
                    .SPM.SmoothGradient,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "BookmarksFeature",
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.PasteboardClient,
                    .Internal.AnalyticsClient,
                    .Internal.PersistenceKeys,
                    .Internal.TCAExtensions,
                    .SPM.SkeletonUI,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "FavoritesRootFeature",
                dependencies: [
                    .Internal.FavoritesFeature,
                    .Internal.BookmarksFeature,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ForumsListFeature",
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ForumFeature",
                dependencies: [
                    .Internal.PageNavigationFeature,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .Internal.TCAExtensions,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "TopicFeature",
                dependencies: [
                    .Internal.PageNavigationFeature,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .Internal.LoggerClient,
                    .Internal.PasteboardClient,
                    .Internal.NotificationCenterClient,
                    .Internal.PersistenceKeys,
                    .Internal.TCAExtensions,
                    .SPM.RichTextKit,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "AnnouncementFeature",
                hasResources: false,
                dependencies: [
                    .Internal.PageNavigationFeature,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .Internal.PersistenceKeys,
                    .Internal.TopicFeature,
                    .SPM.RichTextKit,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "FavoritesFeature",
                dependencies: [
                    .Internal.PageNavigationFeature,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .Internal.NotificationCenterClient,
                    .Internal.TCAExtensions,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "HistoryFeature",
                dependencies: [
                    .Internal.PageNavigationFeature,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .Internal.ParsingClient,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "AuthFeature",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.AnalyticsClient,
                    .Internal.HapticClient,
                    .Internal.PersistenceKeys,
                    .Internal.TCAExtensions,
                    .Internal.SharedUI,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ProfileFeature",
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.AnalyticsClient,
                    .Internal.PersistenceKeys,
                    .SPM.RichTextKit,
                    .SPM.SkeletonUI,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "QMSListFeature",
                hasResources: false,
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.AnalyticsClient,
                    .SPM.SkeletonUI,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "QMSFeature",
                hasResources: false,
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.APIClient,
                    .Internal.AnalyticsClient,
                    .Internal.PersistenceKeys,
                    .SPM.ExyteChat,
                    .SPM.SkeletonUI,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "SettingsFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.PasteboardClient,
                    .Internal.CacheClient,
                    .Internal.TCAExtensions,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.PersistenceKeys,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "NotificationsFeature",
                dependencies: [
                    .Internal.NotificationsClient,
                    .Internal.AnalyticsClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.PersistenceKeys,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "DeveloperFeature",
                hasResources: false,
                dependencies: [
                    .Internal.SharedUI,
                    .Internal.CacheClient,
                    .Internal.AnalyticsClient,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "PageNavigationFeature",
                hasResources: false,
                dependencies: [
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.PersistenceKeys,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
             ),
        
        // MARK: - Clients -
        
            .feature(
                name: "APIClient",
                hasResources: false,
                dependencies: [
                    .Internal.ParsingClient,
                    .Internal.CacheClient,
                    .SPM.PDAPI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "AnalyticsClient",
                hasResources: false,
                dependencies: [
                    .Internal.Models,
                    .Internal.PersistenceKeys,
                    .Internal.LoggerClient,
                    .SPM.PostHog,
                    .SPM.Sentry,
                    .SPM.TCA
                ]
            ),
        .feature(
            name: "ParsingClient",
            hasResources: false,
            dependencies: [
                .Internal.Models,
                .SPM.ZMarkupParser,
                .SPM.TCA,
            ]
        ),
        .feature(
            name: "PasteboardClient",
            hasResources: false,
            dependencies: [
                .SPM.TCA
            ]
        ),
        .feature(
            name: "NotificationsClient",
            dependencies: [
                .Internal.ParsingClient,
                .Internal.AnalyticsClient,
                .Internal.LoggerClient,
                .Internal.CacheClient,
                .SPM.TCA
            ]
        ),
        .feature(
            name: "NotificationCenterClient",
            hasResources: false,
            dependencies: [
                .Internal.LoggerClient,
                .SPM.TCA
            ]
        ),
        .feature(
            name: "HapticClient",
            hasResources: false,
            dependencies: [
                .SPM.TCA
            ]
        ),
        .feature(
            name: "CacheClient",
            hasResources: false,
            dependencies: [
                .Internal.AnalyticsClient,
                .Internal.Models,
                .SPM.Cache,
                .SPM.Nuke,
                .SPM.TCA
            ]
        ),
        .feature(
            name: "LoggerClient",
            hasResources: false,
            dependencies: [
                .SPM.TCA
            ]
        ),
        
        // MARK: - Shared -
        
            .feature(
                name: "Models",
                dependencies: [
                    .SPM.SFSafeSymbols
                ]
            ),
        
            .feature(
                name: "SharedUI",
                hasResources: false,
                dependencies: [
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.SwiftyGif,
                    .SPM.SkeletonUI,
                    .SPM.RichTextKit
                ]
            ),
        
            .feature(
                name: "TCAExtensions",
                dependencies: [
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "PersistenceKeys",
                hasResources: false,
                dependencies: [
                    .Internal.Models,
                    .SPM.TCA
                ]
            ),
        
        // MARK: - Tests -
        
            .target(
                name: "ForPDATests",
                destinations: .iOS,
                product: .unitTests,
                bundleId: "com.subvert.forpda.tests",
                infoPlist: nil,
                sources: ["Modules/Tests/**"],
                resources: [],
                dependencies: [.target(name: "ForPDA")]
            ),
        
        // MARK: - Extensions -
        
            .target(
                name: "SafariExtension",
                destinations: .iOS,
                product: .appExtension,
                bundleId: App.bundleId + "." + "safariextension",
                infoPlist: .safariExtension,
                sources: ["Extensions/Safari/**"],
                resources: ["Extensions/Safari/Resources/**"]
            )
    ]
)

// MARK: - Helpers

struct App {
    static let name = "ForPDA"
    static let destinations: ProjectDescription.Destinations = .iOS
    static let bundleId = "com.subvert.forpda"
}

extension ProjectDescription.Target {
    static func feature(
        name: String,
        productType: ProductType = .framework,
        hasResources: Bool = true,
        dependencies: [TargetDependency]
    ) -> ProjectDescription.Target {
        var resources: [ResourceFileElement] = ["Modules/Resources/**"]
        if hasResources {
            resources.append("Modules/Sources/\(name)/Resources/**")
        }
        return .target(
            name: name,
            destinations: App.destinations,
            product: productType.asProduct(),
            bundleId: App.bundleId + "." + name,
            deploymentTargets: .iOS("16.0"),
            infoPlist: .main,
            sources: ["Modules/Sources/\(name)/**"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(
                base: [
                    "TARGETED_DEVICE_FAMILY": "1",
                    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
                    "PROVISIONING_PROFILE_SPECIFIER": "" // Disables signing for frameworks
                ]
            )
        )
    }
    
    enum ProductType {
        case app, framework
        
        func asProduct() -> ProjectDescription.Product {
            switch self {
            case .app:       return .app
            case .framework: return .framework
            }
        }
    }   
}

extension InfoPlist {
    static let main = InfoPlist.extendingDefault(
        with: [
            "ITSAppUsesNonExemptEncryption": "NO",
            
            "CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)", 
            "CFBundleLocalizations": ["en", "ru"],
            "CFBundleURLTypes": [
                [
                    "CFBundleTypeRole": "Editor",
                    "CFBundleURLName": "com.subvert.forpda",
                    "CFBundleURLSchemes": ["forpda"]
                ]
            ],
            
            "UIAppFonts": ["fontello.ttf"],
            "UILaunchStoryboardName": "LaunchScreen",
            "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            "UIBackgroundModes": ["fetch"],
            
            "BGTaskSchedulerPermittedIdentifiers": ["com.subvert.forpda.background.notifications"],
            
            "NSCameraUsageDescription": "To capture and send photos in QMS",
            "NSMicrophoneUsageDescription": "To send voice messages in QMS",
            "NSPhotoLibraryUsageDescription": "To send attachments in QMS",
            
            "POSTHOG_TOKEN": "$(POSTHOG_TOKEN)",
            "SENTRY_DSN": "$(SENTRY_DSN)"
        ]
    )
    
    static let safariExtension = InfoPlist.dictionary([
        "NSExtension": [
            "NSExtensionPointIdentifier": "com.apple.Safari.web-extension",
            "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).SafarWebExtensionHandler"
        ]
    ])
}

extension TargetDependency {
    struct Internal {}
}

extension TargetDependency.Internal {
    // Features
    static let DeeplinkHandler =        TargetDependency.target(name: "DeeplinkHandler")
    static let ArticlesListFeature =    TargetDependency.target(name: "ArticlesListFeature")
    static let ArticleFeature =         TargetDependency.target(name: "ArticleFeature")
    static let BookmarksFeature =       TargetDependency.target(name: "BookmarksFeature")
    static let ForumsListFeature =      TargetDependency.target(name: "ForumsListFeature")
    static let ForumFeature =           TargetDependency.target(name: "ForumFeature")
    static let TopicFeature =           TargetDependency.target(name: "TopicFeature")
    static let PageNavigationFeature  = TargetDependency.target(name: "PageNavigationFeature")
    static let AnnouncementFeature =    TargetDependency.target(name: "AnnouncementFeature")
    static let FavoritesFeature =       TargetDependency.target(name: "FavoritesFeature")
    static let FavoritesRootFeature =   TargetDependency.target(name: "FavoritesRootFeature")
    static let HistoryFeature =         TargetDependency.target(name: "HistoryFeature")
    static let AuthFeature =            TargetDependency.target(name: "AuthFeature")
    static let ProfileFeature =         TargetDependency.target(name: "ProfileFeature")
    static let QMSListFeature =         TargetDependency.target(name: "QMSListFeature")
    static let QMSFeature =             TargetDependency.target(name: "QMSFeature")
    static let SettingsFeature =        TargetDependency.target(name: "SettingsFeature")
    static let NotificationsFeature =   TargetDependency.target(name: "NotificationsFeature")
    static let DeveloperFeature =       TargetDependency.target(name: "DeveloperFeature")
    
    // Clients
    static let APIClient =           TargetDependency.target(name: "APIClient")
    static let AnalyticsClient =     TargetDependency.target(name: "AnalyticsClient")
    static let CacheClient =         TargetDependency.target(name: "CacheClient")
    static let HapticClient =        TargetDependency.target(name: "HapticClient")
    static let LoggerClient =        TargetDependency.target(name: "LoggerClient")
    static let NotificationsClient = TargetDependency.target(name: "NotificationsClient")
    static let ParsingClient =       TargetDependency.target(name: "ParsingClient")
    static let PasteboardClient =    TargetDependency.target(name: "PasteboardClient")
    static let NotificationCenterClient = TargetDependency.target(name: "NotificationCenterClient")
    
    // Shared
    static let Models =              TargetDependency.target(name: "Models")
    static let SharedUI =            TargetDependency.target(name: "SharedUI")
    static let PersistenceKeys =     TargetDependency.target(name: "PersistenceKeys")
    static let TCAExtensions =       TargetDependency.target(name: "TCAExtensions")
}

extension TargetDependency {
    struct SPM {}
}

extension TargetDependency.SPM {
    static let TCA =            TargetDependency.external(name: "ComposableArchitecture")
    static let PDAPI =          TargetDependency.external(name: "PDAPI_SPM")
    static let AlertToast =     TargetDependency.external(name: "AlertToast")
    static let Cache =          TargetDependency.external(name: "Cache")
    static let ExyteChat =      TargetDependency.external(name: "ExyteChat")
    static let SFSafeSymbols =  TargetDependency.external(name: "SFSafeSymbols")
    static let SwiftyGif =      TargetDependency.external(name: "SwiftyGif")
    static let SkeletonUI =     TargetDependency.external(name: "SkeletonUI")
    static let RichTextKit =    TargetDependency.external(name: "RichTextKit")
    static let Nuke =           TargetDependency.external(name: "Nuke")
    static let NukeUI =         TargetDependency.external(name: "NukeUI")
    static let ZMarkupParser =  TargetDependency.external(name: "ZMarkupParser")
    static let Sentry =         TargetDependency.external(name: "Sentry")
    static let PostHog =        TargetDependency.external(name: "PostHog")
    static let SmoothGradient = TargetDependency.external(name: "SmoothGradient")
    static let YouTubePlayerKit = TargetDependency.external(name: "YouTubePlayerKit")
}
