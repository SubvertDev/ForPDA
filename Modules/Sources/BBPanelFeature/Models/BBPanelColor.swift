//
//  BBPanelColor.swift
//  ForPDA
//
//  Created by Xialtal on 11.03.26.
//

import SwiftUI

enum BBPanelColor: Int, CaseIterable, Identifiable {
    case black      = -16777216
    case white      = -1
    case skyBlue    = -7876885
    case royalBlue  = -12490271
    case blue       = -16776961
    case darkBlue   = -16777077
    case orange     = -23296
    case orangeRed  = -47872
    case crimson    = -2354116
    case red        = -65536
    case darkRed    = -7667712
    case green      = -16711936
    case limeGreen  = -13447886
    case seaGreen   = -13726889
    case deepPink   = -60269
    case tomato     = -40121
    case coral      = -32944
    case purple     = -8388480
    case indigo     = -11861886
    case burlyWood  = -2180985
    case sandyBrown = -5952982
    case sienna     = -7852777
    case chocolate  = -2987746
    case teal       = -16744320
    case silver     = -4144960
    
    var id: Int { self.rawValue }
    
    var color: Color {
        Color(UIColor(argb: self.rawValue))
    }
    
    var title: String {
        let name = String(describing: self)
        return name.prefix(1).uppercased() + name.dropFirst()
    }
}

private extension UIColor {
    convenience init(argb: Int) {
        let value = UInt32(bitPattern: Int32(argb))

        let a = CGFloat((value >> 24) & 0xff) / 255
        let r = CGFloat((value >> 16) & 0xff) / 255
        let g = CGFloat((value >> 8) & 0xff) / 255
        let b = CGFloat(value & 0xff) / 255

        self.init(red: r, green: g, blue: b, alpha: a)
    }
}
