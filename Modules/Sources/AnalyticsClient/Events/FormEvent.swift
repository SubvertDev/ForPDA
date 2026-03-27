//
//  FormEvent.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 13.12.2025.
//

public enum FormEvent: Event {

    case formSent
    case publishTapped
    case dismissTapped
    case previewTapped
    
    public var name: String {
        return "Form " + eventName(for: self).inProperCase
    }
    
    public var properties: [String: String]? {
        switch self {
        default:
            return nil
        }
    }
}
