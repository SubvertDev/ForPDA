import ProjectDescription

let project = Project(
    name: "ForPDA",
    settings: .projectSettings(),
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
                .target(name: "AppFeature"),
                .target(name: "SafariExtension"),
                .SPM.TCA
            ],
            settings: .settings(base: .appSettings, defaultSettings: .recommended)
        ),
        
        // MARK: - Features
        
            .feature(
                name: "AppFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.AnnouncementFeature,
                    .Internal.ArticleFeature,
                    .Internal.ArticlesListFeature,
                    .Internal.AuthFeature,
                    .Internal.BookmarksFeature,
                    .Internal.CacheClient,
                    .Internal.DeeplinkHandler,
                    .Internal.DeveloperFeature,
                    .Internal.FavoritesFeature,
                    .Internal.FavoritesRootFeature,
                    .Internal.ForumFeature,
                    .Internal.ForumsListFeature,
                    .Internal.HistoryFeature,
                    .Internal.LoggerClient,
                    .Internal.Models,
                    .Internal.NotificationsClient,
                    .Internal.NotificationsFeature,
                    .Internal.ProfileFeature,
                    .Internal.QMSFeature,
                    .Internal.QMSListFeature,
                    .Internal.ReputationChangeFeature,
                    .Internal.ReputationFeature,
                    .Internal.SearchFeature,
                    .Internal.SearchResultFeature,
                    .Internal.SettingsFeature,
                    .Internal.TCAExtensions,
                    .Internal.ToastClient,
                    .Internal.TopicFeature,
                    .Internal.WriteFormFeature,
                    .SPM.AlertToast,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "AnnouncementFeature",
                hasResources: false,
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.PageNavigationFeature,
                    .Internal.ParsingClient,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.ToastClient,
                    .Internal.TopicBuilder,
                    .SPM.NukeUI,
                    .SPM.RichTextKit,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ArticleFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.GalleryFeature,
                    .Internal.HapticClient,
                    .Internal.Models,
                    .Internal.NotificationsClient,
                    .Internal.ParsingClient,
                    .Internal.PasteboardClient,
                    .Internal.ReputationChangeFeature,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .Internal.ToastClient,
                    .Internal.WriteFormFeature,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.SkeletonUI,
                    .SPM.SmoothGradient,
                    .SPM.TCA,
                    .SPM.YouTubePlayerKit
                ]
            ),
        
            .feature(
                name: "ArticlesListFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.HapticClient,
                    .Internal.Models,
                    .Internal.PasteboardClient,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .Internal.ToastClient,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "AuthFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.HapticClient,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "BookmarksFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.PasteboardClient,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .SPM.NukeUI,
                    .SPM.SkeletonUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "DeeplinkHandler",
                hasResources: false,
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.LoggerClient,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "DeveloperFeature",
                hasResources: false,
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.CacheClient,
                    .Internal.SharedUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "FavoritesFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.NotificationsClient,
                    .Internal.PageNavigationFeature,
                    .Internal.PasteboardClient,
                    .Internal.ParsingClient,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .Internal.ToastClient,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "FavoritesRootFeature",
                dependencies: [
                    .Internal.BookmarksFeature,
                    .Internal.FavoritesFeature,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ForumFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.PageNavigationFeature,
                    .Internal.ParsingClient,
                    .Internal.PasteboardClient,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .Internal.ToastClient,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ForumsListFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.ParsingClient,
                    .Internal.SharedUI,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "GalleryFeature",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .SPM.Nuke,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "HistoryFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.PageNavigationFeature,
                    .Internal.ParsingClient,
                    .Internal.SharedUI,
                    .SPM.NukeUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "NotificationsFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.NotificationsClient,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ProfileFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.BBBuilder,
                    .Internal.HapticClient,
                    .Internal.Models,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.ToastClient,
                    .SPM.NukeUI,
                    .SPM.RichTextKit,
                    .SPM.SFSafeSymbols,
                    .SPM.SkeletonUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "PageNavigationFeature",
                dependencies: [
                    .Internal.Models,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
             ),
        
            .feature(
                name: "QMSListFeature",
                hasResources: false,
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.QMSClient,
                    .Internal.SharedUI,
                    .SPM.NukeUI,
                    .SPM.SkeletonUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "QMSFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.BBBuilder,
                    .Internal.Models,
                    .Internal.NotificationsClient,
                    .Internal.PersistenceKeys,
                    .Internal.QMSClient,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .SPM.ExyteChat,
                    .SPM.NukeUI,
                    .SPM.SkeletonUI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "ReputationChangeFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.ToastClient,
                    .Internal.TCAExtensions,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
             ),
        
            .feature(
                name: "ReputationFeature",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .Internal.WriteFormFeature,
                    .SPM.TCA,
                ]
             ),
        
            .feature(
                name: "SearchFeature",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .SPM.TCA,
                ]
            ),
            
            .feature(
                name: "SearchResultFeature",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.PageNavigationFeature,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.ToastClient,
                    .Internal.TopicBuilder,
                    .SPM.TCA,
                ]
            ),
        
            .feature(
                name: "SettingsFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.PasteboardClient,
                    .Internal.PersistenceKeys,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "TopicBuilder",
                dependencies: [
                    .Internal.BBBuilder,
                    .Internal.CacheClient,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .SPM.NukeUI,
                    .SPM.SFSafeSymbols,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "TopicFeature",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.APIClient,
                    .Internal.CacheClient,
                    .Internal.DeeplinkHandler,
                    .Internal.GalleryFeature,
                    .Internal.LoggerClient,
                    .Internal.Models,
                    .Internal.NotificationsClient,
                    .Internal.PageNavigationFeature,
                    .Internal.ParsingClient,
                    .Internal.PasteboardClient,
                    .Internal.PersistenceKeys,
                    .Internal.ReputationChangeFeature,
                    .Internal.SharedUI,
                    .Internal.TCAExtensions,
                    .Internal.ToastClient,
                    .Internal.TopicBuilder,
                    .Internal.WriteFormFeature,
                    .SPM.MemberwiseInit,
                    .SPM.NukeUI,
                    .SPM.RichTextKit,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "WriteFormFeature",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.ParsingClient,
                    .Internal.SharedUI,
                    .Internal.TopicBuilder,
                    .SPM.NukeUI,
                    .SPM.RichTextKit,
                    .SPM.TCA,
                ]
            ),
        
        // MARK: - Clients -
        
            .feature(
                name: "APIClient",
                hasResources: false,
                dependencies: [
                    .Internal.CacheClient,
                    .Internal.ParsingClient,
                    .SPM.PDAPI,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "AnalyticsClient",
                hasResources: false,
                dependencies: [
                    .Internal.LoggerClient,
                    .Internal.Models,
                    .Internal.PersistenceKeys,
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
                    .Internal.SharedUI,
                    .SPM.TCA,
                    .SPM.ZMarkupParser,
                ]
            ),
        
            .feature(
                name: "ToastClient",
                dependencies: [
                    .Internal.HapticClient,
                    .Internal.Models,
                    .SPM.TCA
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
                    .Internal.AnalyticsClient,
                    .Internal.CacheClient,
                    .Internal.LoggerClient,
                    .Internal.ParsingClient,
                    .SPM.TCA
                ]
            ),
        
            .feature(
                name: "QMSClient",
                dependencies: [
                    .Internal.APIClient,
                    .Internal.Models,
                    .Internal.ParsingClient,
                    .Internal.NotificationsClient,
                    .SPM.PDAPI,
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
                dependencies: [
                    .Internal.Models,
                    .SPM.NukeUI,
                    .SPM.RichTextKit,
                    .SPM.SFSafeSymbols,
                    .SPM.SkeletonUI,
                    .SPM.SwiftyGif
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
        
            .feature(
                name: "BBBuilder",
                dependencies: [
                    .Internal.AnalyticsClient,
                    .Internal.LoggerClient,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .SPM.TCA
                ]
            ),
        
        // MARK: - Tests -
        
            .target(
                name: "ForPDATests",
                destinations: .iOS,
                product: .unitTests,
                bundleId: "com.subvert.forpda.tests",
                deploymentTargets: .iOS("16.0"),
                infoPlist: .default,
                sources: ["Modules/Tests/**"],
                resources: [],
                dependencies: [
                    .target(name: "ForPDA"),
                    .Internal.ArticlesListFeature,
                    .Internal.BBBuilder,
                    .Internal.Models,
                    .Internal.SharedUI,
                    .SPM.TCA
                ]
            ),
        
        .tests(
            name: "BBBuilderTests",
            dependencies: [
                .Internal.BBBuilder,
                .Internal.Models,
                .Internal.SharedUI
            ]
        ),
        
        // MARK: - Extensions -
        
            .target(
                name: "SafariExtension",
                destinations: .iOS,
                product: .appExtension,
                bundleId: App.bundleId + "." + "safariextension",
                deploymentTargets: .iOS("16.0"),
                infoPlist: .safariExtension,
                sources: ["Extensions/Safari/**"],
                resources: [
                    .glob(
                        pattern: "Extensions/Safari/Resources/**",
                        excluding: [
                            "Extensions/Safari/Resources/_locales/**",
                            "Extensions/Safari/Resources/images/**"
                        ]
                    ),
                    .folderReference(path: "Extensions/Safari/Resources/_locales"),
                    .folderReference(path: "Extensions/Safari/Resources/images")
                ],
                settings: .settings(
                    base: SettingsDictionary()
                        .manualCodeSigning(
                            identity: "iPhone Developer",
                            provisioningProfileSpecifier: "match Development com.subvert.forpda.safariextension"
                        )
                        .setDevelopmentTeam("7353CQCGQC")
                        .merging([
                            "TARGETED_DEVICE_FAMILY": "1",
                            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO"
                        ])
                )
            )
    ],
    resourceSynthesizers: [
        .plists(),
        .fonts(),
        .custom(name: "UI", parser: .assets, extensions: ["xcassets"])
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
        productType: Product = defaultProductType(),
        hasResources: Bool = true,
        dependencies: [TargetDependency]
    ) -> ProjectDescription.Target {
        
        var resources: [ResourceFileElement] = []
        if hasResources {
            resources.append("Modules/Sources/\(name)/Resources/**")
        }
        
        var infoPlist: InfoPlist = .default
        if name == "SharedUI" {
            infoPlist = .extendingDefault(with: ["UIAppFonts": "fontello.ttf"])
        }
        
        return .target(
            name: name,
            destinations: App.destinations,
            product: productType,
            bundleId: App.bundleId + "." + name,
            deploymentTargets: .iOS("16.0"),
            infoPlist: infoPlist,
            sources: ["Modules/Sources/\(name)/**"],
            resources: .resources(resources),
            dependencies: dependencies,
            settings: .settings(
                base: .targetSettings,
                defaultSettings: .recommended
            )
        )
    }
    
    static func tests(name: String, dependencies: [TargetDependency]) -> ProjectDescription.Target {
        return .target(
            name: name,
            destinations: App.destinations,
            product: .unitTests,
            bundleId: App.bundleId + "." + name + ".Tests",
            deploymentTargets: .iOS("16.0"),
            infoPlist: .default,
            sources: ["Modules/Tests/\(name)/**"],
            resources: ["Modules/Resources/**"],
            dependencies: dependencies
        )
    }
    
    static func defaultProductType() -> ProjectDescription.Product {
        if case let .string(linking) = Environment.linking {
            return linking == "static" ? .staticFramework : .framework
        } else {
            return .framework
        }
    }
}

// MARK: - Settings Extension

extension Settings {
    
    static func projectSettings() -> ProjectDescription.Settings {
        return .settings(
            base: SettingsDictionary()
                .swiftVersion("6.0")
                .otherSwiftFlags(.longTypeCheckingFlags)
                .enableL10nGeneration(),
            configurations: [
                .debug(name: "Debug", xcconfig: "Configs/App.xcconfig"),
                .release(name: "Release", settings: .init().enableDsym(), xcconfig: "Configs/App.xcconfig"),
            ]
        )
    }
}

extension SettingsDictionary {
    static let appSettings = SettingsDictionary()
        .merging(.targetSettings)
        .setAppName(App.name)
        .setDevelopmentTeam("7353CQCGQC")
    
        .includeAppIcon()
        .merging(["CODE_SIGNING_ALLOWED": .string("YES")])
        .manualCodeSigning(
            identity: "Apple Development",
            provisioningProfileSpecifier: "match Development com.subvert.forpda"
        )
    
    static let targetSettings = SettingsDictionary()
        .useIPhoneAsSingleDestination()
        .disableAssetGeneration()
        .excludeAppIcon()
        .disableCodeSigning()
}

extension Dictionary where Key == String, Value == SettingValue {
    func setAppName(_ name: String) -> SettingsDictionary {
        return merging(["INFOPLIST_KEY_CFBundleDisplayName": .string(name)])
    }
    
    func setDevelopmentTeam(_ teamId: String) -> SettingsDictionary {
        return merging(["DEVELOPMENT_TEAM[sdk=iphoneos*]": .string(teamId)])
    }
    
    func disableAssetGeneration() -> SettingsDictionary {
        return merging(["ASSETCATALOG_COMPILER_GENERATE_ASSET_SYMBOLS": .string("NO")])
    }
    
    func includeAppIcon() -> SettingsDictionary {
        return merging(["ASSETCATALOG_COMPILER_APPICON_NAME": .string("AppIcon-$(RELEASE_CHANNEL)")])
    }
    
    func excludeAppIcon() -> SettingsDictionary {
        return merging(["ASSETCATALOG_COMPILER_APPICON_NAME": .string("")])
    }
    
    func disableCodeSigning() -> SettingsDictionary {
        return merging(["CODE_SIGNING_ALLOWED": .string("NO")])
            .manualCodeSigning(identity: nil, provisioningProfileSpecifier: nil)
    }
    
    func useIPhoneAsSingleDestination() -> SettingsDictionary {
        return merging([
            "TARGETED_DEVICE_FAMILY": "1",
            "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO"
        ])
    }
    
    func enableL10nGeneration() -> SettingsDictionary {
        return merging([
            "SWIFT_EMIT_LOC_STRINGS": "YES",
            "LOCALIZATION_EXPORT_SUPPORTED": "YES",
            "LOCALIZATION_PREFERS_STRING_CATALOGS": "YES"
        ])
    }
    
    func enableDsym() -> SettingsDictionary {
        return merging(["DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym"])
    }
}

extension Array where Element == String {
    static let longTypeCheckingFlags = [
        "-Xfrontend",
        "-warn-long-function-bodies=700",
        "-Xfrontend",
        "-warn-long-expression-type-checking=150"
    ]
}

// MARK: - InfoPlist extension

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
            
            "UILaunchStoryboardName": "LaunchScreen",
            "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
            "UIBackgroundModes": ["fetch"],
            
            "BGTaskSchedulerPermittedIdentifiers": ["com.subvert.forpda.background.notifications"],
            
            "NSCameraUsageDescription": "To capture and send photos in QMS",
            "NSMicrophoneUsageDescription": "To send voice messages in QMS",
            "NSPhotoLibraryUsageDescription": "To send attachments in QMS",
            
            "POSTHOG_TOKEN": "$(POSTHOG_TOKEN)",
            "SENTRY_DSN": "$(SENTRY_DSN)",
            "RELEASE_CHANNEL": "$(RELEASE_CHANNEL)"
        ]
    )
    
    static let safariExtension = InfoPlist.extendingDefault(
        with: [
            "CFBundleDisplayName": "$(PRODUCT_NAME)",
            "CFBundleShortVersionString": "$(MARKETING_VERSION)",
            "CFBundleVersion": "$(CURRENT_PROJECT_VERSION)",
            "NSExtension": [
                "NSExtensionPointIdentifier": "com.apple.Safari.web-extension",
                "NSExtensionPrincipalClass": "$(PRODUCT_MODULE_NAME).SafarWebExtensionHandler"
            ]
        ]
    )
}

// MARK: - Dependencies

extension TargetDependency {
    struct Internal {}
}

extension TargetDependency.Internal {
    // Features
    static let AnnouncementFeature =    TargetDependency.target(name: "AnnouncementFeature")
    static let ArticleFeature =         TargetDependency.target(name: "ArticleFeature")
    static let ArticlesListFeature =    TargetDependency.target(name: "ArticlesListFeature")
    static let AuthFeature =            TargetDependency.target(name: "AuthFeature")
    static let BookmarksFeature =       TargetDependency.target(name: "BookmarksFeature")
    static let DeeplinkHandler =        TargetDependency.target(name: "DeeplinkHandler")
    static let DeveloperFeature =       TargetDependency.target(name: "DeveloperFeature")
    static let FavoritesFeature =       TargetDependency.target(name: "FavoritesFeature")
    static let FavoritesRootFeature =   TargetDependency.target(name: "FavoritesRootFeature")
    static let ForumFeature =           TargetDependency.target(name: "ForumFeature")
    static let ForumsListFeature =      TargetDependency.target(name: "ForumsListFeature")
    static let GalleryFeature =         TargetDependency.target(name: "GalleryFeature")
    static let HistoryFeature =         TargetDependency.target(name: "HistoryFeature")
    static let NotificationsFeature =   TargetDependency.target(name: "NotificationsFeature")
    static let PageNavigationFeature =  TargetDependency.target(name: "PageNavigationFeature")
    static let ProfileFeature =         TargetDependency.target(name: "ProfileFeature")
    static let QMSFeature =             TargetDependency.target(name: "QMSFeature")
    static let QMSListFeature =         TargetDependency.target(name: "QMSListFeature")
    static let ReputationChangeFeature = TargetDependency.target(name: "ReputationChangeFeature")
    static let ReputationFeature =      TargetDependency.target(name: "ReputationFeature")
    static let SearchFeature =          TargetDependency.target(name: "SearchFeature")
    static let SearchResultFeature =    TargetDependency.target(name: "SearchResultFeature")
    static let SettingsFeature =        TargetDependency.target(name: "SettingsFeature")
    static let TopicBuilder =           TargetDependency.target(name: "TopicBuilder")
    static let TopicFeature =           TargetDependency.target(name: "TopicFeature")
    static let WriteFormFeature =       TargetDependency.target(name: "WriteFormFeature")
    
    // Clients
    static let AnalyticsClient =     TargetDependency.target(name: "AnalyticsClient")
    static let APIClient =           TargetDependency.target(name: "APIClient")
    static let CacheClient =         TargetDependency.target(name: "CacheClient")
    static let HapticClient =        TargetDependency.target(name: "HapticClient")
    static let LoggerClient =        TargetDependency.target(name: "LoggerClient")
    static let NotificationsClient = TargetDependency.target(name: "NotificationsClient")
    static let ParsingClient =       TargetDependency.target(name: "ParsingClient")
    static let PasteboardClient =    TargetDependency.target(name: "PasteboardClient")
    static let QMSClient =           TargetDependency.target(name: "QMSClient")
    static let ToastClient =         TargetDependency.target(name: "ToastClient")
    
    // Shared
    static let BBBuilder =           TargetDependency.target(name: "BBBuilder")
    static let Models =              TargetDependency.target(name: "Models")
    static let PersistenceKeys =     TargetDependency.target(name: "PersistenceKeys")
    static let SharedUI =            TargetDependency.target(name: "SharedUI")
    static let TCAExtensions =       TargetDependency.target(name: "TCAExtensions")
}

extension TargetDependency {
    struct SPM {}
}

extension TargetDependency.SPM {
    static let AlertToast =     TargetDependency.external(name: "AlertToast")
    static let Cache =          TargetDependency.external(name: "Cache")
    static let ExyteChat =      TargetDependency.external(name: "ExyteChat")
    static let MemberwiseInit = TargetDependency.external(name: "MemberwiseInit")
    static let Nuke =           TargetDependency.external(name: "Nuke")
    static let NukeUI =         TargetDependency.external(name: "NukeUI")
    static let PDAPI =          TargetDependency.external(name: "PDAPI_SPM")
    static let PostHog =        TargetDependency.external(name: "PostHog")
    static let RichTextKit =    TargetDependency.external(name: "RichTextKit")
    static let Sentry =         TargetDependency.external(name: "SentrySwiftUI")
    static let SFSafeSymbols =  TargetDependency.external(name: "SFSafeSymbols")
    static let SkeletonUI =     TargetDependency.external(name: "SkeletonUI")
    static let SmoothGradient = TargetDependency.external(name: "SmoothGradient")
    static let SwiftyGif =      TargetDependency.external(name: "SwiftyGif")
    static let TCA =            TargetDependency.external(name: "ComposableArchitecture")
    static let YouTubePlayerKit = TargetDependency.external(name: "YouTubePlayerKit")
    static let ZMarkupParser =  TargetDependency.external(name: "ZMarkupParser")
}
