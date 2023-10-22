//
//  HTTPHeader.swift
//  ForPDA
//
//  Created by Subvert on 19.10.2023.
//

enum HTTPHeader {
    case authorization(String)
    case contentType(ContentType)
    
    var header: (field: String, value: String) {
        switch self {
        case .authorization(let value): return (field: "Authorization", value: "Bearer \(value)")
        case .contentType(let value):   return (field: "Content-Type", value: value.rawValue)
        }
    }
}

extension HTTPHeader {
    enum ContentType: String {
        case json = "application/json"
    }
}
