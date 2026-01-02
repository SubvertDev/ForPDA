//
//  BBPanelTag.swift
//  ForPDA
//
//  Created by Xialtal on 1.01.26.
//

import SFSafeSymbols

public enum BBPanelTag {
    case b
    case i
    case s
    case u
    case sup
    case sub
    case size
    case color
    case url
    case offtop
    case center
    case left
    case right
    case spoiler
    case spoilerWithTitle
    case listBullet
    case listNumber
    case quote
    case code
    case hide
    case cur
    case mod
    case ex
    
    case upload
}

extension BBPanelTag {
    
    var code: String {
        switch self {
        case .spoilerWithTitle:
            "SPOILER"
        case .listBullet:
            "LIST"
        case .listNumber:
            "LIST=1"
        default:
            "\(self)".uppercased()
        }
    }
    
    var icon: SFSymbol {
        switch self {
        case .b:
            return .bold
        case .i:
            return .italic
        case .s:
            return .strikethrough
        case .u:
            return .underline
        case .sup:
            return .textformatSuperscript
        case .sub:
            return .textformatSubscript
        case .size:
            return .textformat
        case .color:
            return .paintbrushPointedFill
        case .url:
            return .link
        case .offtop:
            return .cupAndSaucer
        case .center:
            return .alignHorizontalCenter
        case .left:
            return .alignHorizontalLeft
        case .right:
            return .alignHorizontalRight
        case .spoiler:
            return .plusAppFill
        case .spoilerWithTitle:
            return .hSquareFill
        case .listBullet:
            return .listBullet
        case .listNumber:
            return .listNumber
        case .quote:
            return .quoteOpening
        case .code:
            return .chevronLeftForwardslashChevronRight
        case .hide:
            return .eyeSlash
        case .cur:
            return .kSquare
        case .mod:
            return .mSquare
        case .ex:
            return .exclamationmarkSquare
        case .upload:
            return .paperclip
        }
    }
}
