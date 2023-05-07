//
//  NetworkManager.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import SwiftSoup

enum NetworkError {
    
}

final class NetworkManager {
    
    private let startPageURL = URL(string: "https://4pda.to/")!
    
    func getArticles(atPage number: Int = 1) async throws -> Document {
        let url = URL(string: "https://4pda.to/page/\(number)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let htmlString = convertDataToCyrillicString(data)
        let parsed = try SwiftSoup.parse(htmlString)
        return parsed
    }
    
    func getArticlePage(url: URL) async throws -> Document {
        let (data, _) = try await URLSession.shared.data(from: url)
        let htmlString = convertDataToCyrillicString(data)
        let parsed = try SwiftSoup.parse(htmlString)
        return parsed
    }
    
    // MARK: - Helpers
    
    private func convertDataToCyrillicString(_ data: Data) -> String {
        let string = String(data: data, encoding: .isoLatin1)!
        
        let string2 = string.replacingOccurrences(of: "\u{98}", with: "")
        let string3 = string2.replacingOccurrences(of: "\u{ad}", with: "") // optionally
        let string4 = string3.replacingOccurrences(of: "\u{a0}", with: "") // optionally
        
        let data2 = string4.data(using: .isoLatin1)!
        let stringFinal = String(data: data2, encoding: .windowsCP1251)!
        
        return stringFinal
    }
    
    // Backup version
    private func convertToUTF8(_ data: Data) -> String {
        var data = data
        data.removeAll { $0 == 0x98 }
        
        guard let cfstring = CFStringCreateFromExternalRepresentation(nil, data as CFData, CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue)) else { preconditionFailure() }
        
        let size = CFStringGetMaximumSizeForEncoding(CFStringGetLength(cfstring), CFStringBuiltInEncodings.UTF8.rawValue)
        let buffer = malloc(size).bindMemory(to: CChar.self, capacity: size)
        guard CFStringGetCString(cfstring, buffer, size, CFStringBuiltInEncodings.UTF8.rawValue) else {
            free(buffer)
            preconditionFailure()
        }
        
        let string = String(cString: buffer)
        free(buffer)
        
        return string
    }
}
