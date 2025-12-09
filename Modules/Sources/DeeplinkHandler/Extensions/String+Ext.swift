//
//  String+Ext.swift
//  ForPDA
//
//  Created by Xialtal on 4.12.25.
//

import Foundation

extension String {
    func unEscape() -> String? {
        guard let decode = decodeURLString(self, encoding: .windowsCP1251) else {
            return nil
        }
        var result = decode
        if result.contains("\u{FFFD}") { // if contains UTF-8 symbol, trying to decode as UTF-8
            if let utf8Decode = decodeURLString(self, encoding: .utf8), !utf8Decode.contains("\u{FFFD}") {
                result = utf8Decode
            }
        }
        if result.contains("%") { // If string still contains % symbol - decoding once again
            if let doubleDecode = decodeURLString(result, encoding: .windowsCP1251) {
                result = doubleDecode
            }
        }
        return result
    }
    
    private func decodeURLString(_ str: String, encoding: Encoding) -> String? {
        var bytes = [UInt8]()
        var index = str.startIndex
        while index < str.endIndex {
            if str[index] == "%" {
                let hexStart = str.index(after: index)
                if hexStart < str.endIndex {
                    let hexEnd = str.index(hexStart, offsetBy: 2, limitedBy: str.endIndex) ?? str.endIndex
                    if let byte = UInt8(str[hexStart..<hexEnd], radix: 16) {
                        bytes.append(byte)
                        index = hexEnd
                        continue
                    }
                }
            } else if str[index] == "+" {
                // replace + symbol to space
                bytes.append(0x20)
            } else { // default symbol
                if let byte = str[index].asciiValue {
                    bytes.append(byte)
                }
            }
            index = str.index(after: index)
        }
        return String(data: Data(bytes), encoding: encoding)
    }
}
