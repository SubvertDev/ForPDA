//
//  SharedUI.swift
//  
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import Models
import SwiftUI

//public let shared = Bundle.module

public extension Bundle {
    static let shared = Bundle.module
}

@available(iOS, deprecated: 26.0)
public var isLiquidGlass: Bool {
    if #available(iOS 26.0, *) {
        return true
    } else {
        return false
    }
}

public extension Bool {
    var inverted: Self {
        get { !self }
        set { self = !newValue }
    }
}

private struct TintKey: EnvironmentKey {
    static let defaultValue: Color = Color.blue
}

public struct BackgroundColors: Sendable {
    
    public let forcedDark: Color
    public let primary: Color
    public let primaryAlpha: Color
    public let secondary: Color
    public let tertiary: Color

    public static let blue = Self(
        forcedDark: Color(.Background.Blue.forcedDark),
        primary: Color(.Background.Blue.primary),
        primaryAlpha: Color(.Background.Blue.primaryAlpha),
        secondary: Color(.Background.Blue.secondary),
        tertiary: Color(.Background.Blue.tertiary)
    )

    public static let black = Self(
        forcedDark: Color(.Background.Black.primary),
        primary: Color(.Background.Black.primary),
        primaryAlpha: Color(.Background.Black.primaryAlpha),
        secondary: Color(.Background.Black.secondary),
        tertiary: Color(.Background.Black.tertiary)
    )

    public static func resolve(
        theme: BackgroundTheme,
        appColorScheme: AppColorScheme,
        systemColorScheme: ColorScheme
    ) -> Self {
        guard case .black = theme else { return .blue }

        let isDark: Bool
        switch appColorScheme {
        case .light:
            isDark = false
        case .dark:
            isDark = true
        case .system:
            isDark = systemColorScheme == .dark
        }

        return isDark ? .black : .blue
    }
}

private struct BackgroundColorsKey: EnvironmentKey {
    static let defaultValue = BackgroundColors.blue
}

public extension EnvironmentValues {
    var tintColor: Color {
        get { self[TintKey.self] }
        set { self[TintKey.self] = newValue }
    }

    var backgroundColors: BackgroundColors {
        get { self[BackgroundColorsKey.self] }
        set { self[BackgroundColorsKey.self] = newValue }
    }
}

public extension UIColor {
    // Used in BBCodeParser since SwiftUI Color refuses to work with no reason
    static let primaryLabel = UIColor(resource: .Labels.primary)
}

public extension Color {
    init(hex: Int, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: opacity
        )
    }
}

extension Color {
    public init(dynamicTuple: (String, String)) {
        self.init(UIColor { traitCollection in
            let hex = traitCollection.userInterfaceStyle == .dark ? dynamicTuple.1 : dynamicTuple.0
            return UIColor(Color(hex: hex))
        })
    }

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
