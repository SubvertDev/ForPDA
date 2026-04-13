//
//  DeviceTypeEvent.swift
//  ForPDA
//
//  Created by Xialtal on 13.04.26.
//

public enum DeviceTypeEvent: Event {

    case typeTapped(String)
    case deviceTapped(String)
    case vendorTapped(String, type: String)
    
    public var name: String {
        return "DeviceType " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        case .deviceTapped(let tag):
            return ["tag": name]
        case .typeTapped(let type):
            return ["type": type]
        case .vendorTapped(let name, let type):
            return ["type": type, "name": name]
        }
    }
}
