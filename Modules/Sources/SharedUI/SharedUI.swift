//
//  SharedUI.swift
//  
//
//  Created by Ilia Lubianoi on 12.05.2024.
//

import SwiftUI

@available(iOS, deprecated: 26.0)
public var isLiquidGlass: Bool {
    if #available(iOS 26.0, *) {
        return true
    } else {
        return false
    }
}

private struct TintKey: EnvironmentKey {
    static let defaultValue: Color = Color.blue
}

public extension EnvironmentValues {
    var tintColor: Color {
        get { self[TintKey.self] }
        set { self[TintKey.self] = newValue }
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
