//
//  SharedUI.swift
//  
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI

private struct TintKey: EnvironmentKey {
    static let defaultValue: Color = Color.blue
}

public extension EnvironmentValues {
    var tintColor: Color {
        get { self[TintKey.self] }
        set { self[TintKey.self] = newValue }
    }
}

// MARK: - Images

// TODO: 17+ change to ImageResource
public extension Image {
    static let logoLight = Image(.logoLight)
    static let avatarDefault = Image(.avatarDefault)
    static let github = Image(.github)
    static let telegram = Image(.telegram)
    static let quote = Image(.quote)
    
    struct Settings {
        public static let lightThemeExample = Image(.Settings.lightThemeExample)
        public static let darkThemeExample = Image(.Settings.darkThemeExample)
        public static let systemThemeExample = Image(.Settings.systemThemeExample)
        public static let circleBlue = Image(.Settings.circleBlue)
        public static let circleDark = Image(.Settings.circleDark)
        
        public struct Theme {
            public static let circleLettuce = Image(.Settings.Theme.circleLettuce)
            public static let circleOrange = Image(.Settings.Theme.circleOrange)
            public static let circlePink = Image(.Settings.Theme.circlePink)
            public static let circlePrimary = Image(.Settings.Theme.circlePrimary)
            public static let circlePurple = Image(.Settings.Theme.circlePurple)
            public static let circleScarlet = Image(.Settings.Theme.circleScarlet)
            public static let circleSky = Image(.Settings.Theme.circleSky)
            public static let circleYellow = Image(.Settings.Theme.circleYellow)
        }
    }
}

public extension Color {
    struct Main {
        public static let red = Color(.Main.red)
        public static let greyAlpha = Color(.Main.greyAlpha)
        public static let primaryAlpha = Color(.Main.primaryAlpha)
    }
    
    struct Labels {
        public static let primary = Color(.Labels.primary)
        public static let primaryInvariably = Color(.Labels.primaryInvariably)
        public static let secondary = Color(.Labels.secondary)
        public static let secondaryInvariably = Color(.Labels.secondaryInvariably)
        public static let teritary = Color(.Labels.teritary)
        public static let quaternary = Color(.Labels.quaternary)
        public static let quintuple = Color(.Labels.quintuple)
        public static let forcedLight = Color(.Labels.forcedLight)
    }
    
    struct Background {
        public static let primary = Color(.Background.primary)
        public static let primaryAlpha = Color(.Background.primaryAlpha)
        public static let teritary = Color(.Background.teritary)
        public static let forcedDark = Color(.Background.forcedDark)
    }
    
    struct Separator {
        public static let primary = Color(.Separator.primary)
        public static let secondary = Color(.Separator.secondary)
    }
    
    struct Theme {
        public static let primary = Color(.Theme.primary)
        public static let lettuce = Color(.Theme.lettuce)
        public static let orange = Color(.Theme.orange)
        public static let pink = Color(.Theme.pink)
        public static let purple = Color(.Theme.purple)
        public static let scarlet = Color(.Theme.scarlet)
        public static let sky = Color(.Theme.sky)
        public static let yellow = Color(.Theme.yellow)
    }
}

extension Color {
     
    // MARK: - Text Colors
    static let lightText = Color(UIColor.lightText)
    static let darkText = Color(UIColor.darkText)
    static let placeholderText = Color(UIColor.placeholderText)

    // MARK: - Label Colors
    static let label = Color(UIColor.label)
    static let secondaryLabel = Color(UIColor.secondaryLabel)
    static let tertiaryLabel = Color(UIColor.tertiaryLabel)
    static let quaternaryLabel = Color(UIColor.quaternaryLabel)

    // MARK: - Background Colors
    static let systemBackground = Color(UIColor.systemBackground)
    static let secondarySystemBackground = Color(UIColor.secondarySystemBackground)
    static let tertiarySystemBackground = Color(UIColor.tertiarySystemBackground)
    
    // MARK: - Fill Colors
    static let systemFill = Color(UIColor.systemFill)
    static let secondarySystemFill = Color(UIColor.secondarySystemFill)
    static let tertiarySystemFill = Color(UIColor.tertiarySystemFill)
    static let quaternarySystemFill = Color(UIColor.quaternarySystemFill)
    
    // MARK: - Grouped Background Colors
    static let systemGroupedBackground = Color(UIColor.systemGroupedBackground)
    static let secondarySystemGroupedBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let tertiarySystemGroupedBackground = Color(UIColor.tertiarySystemGroupedBackground)
    
    // MARK: - Gray Colors
    static let systemGray = Color(UIColor.systemGray)
    static let systemGray2 = Color(UIColor.systemGray2)
    static let systemGray3 = Color(UIColor.systemGray3)
    static let systemGray4 = Color(UIColor.systemGray4)
    static let systemGray5 = Color(UIColor.systemGray5)
    static let systemGray6 = Color(UIColor.systemGray6)
    
    // MARK: - Other Colors
    static let separator = Color(UIColor.separator)
    static let opaqueSeparator = Color(UIColor.opaqueSeparator)
    static let link = Color(UIColor.link)
    
    // MARK: System Colors
    static let systemBlue = Color(UIColor.systemBlue)
    static let systemPurple = Color(UIColor.systemPurple)
    static let systemGreen = Color(UIColor.systemGreen)
    static let systemYellow = Color(UIColor.systemYellow)
    static let systemOrange = Color(UIColor.systemOrange)
    static let systemPink = Color(UIColor.systemPink)
    static let systemRed = Color(UIColor.systemRed)
    static let systemTeal = Color(UIColor.systemTeal)
    static let systemIndigo = Color(UIColor.systemIndigo)
    
    @available(iOS 15.0, *)
    static let tintColor = Color(UIColor.tintColor)
    @available(iOS 13.0, *)
    static let systemBrown = Color(UIColor.systemBrown)
    @available(iOS 15.0, *)
    static let systemMint = Color(UIColor.systemMint)
    @available(iOS 15.0, *)
    static let systemCyan = Color(UIColor.systemCyan)
}

extension Color {
    public init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0

        var red: Double = 0.0
        var green: Double = 0.0
        var blue: Double = 0.0
        let opacity: Double = 1.0

        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
            return
        }

        red = Double((rgb & 0xFF0000) >> 16) / 255.0
        green = Double((rgb & 0x00FF00) >> 8) / 255.0
        blue = Double(rgb & 0x0000FF) / 255.0

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
