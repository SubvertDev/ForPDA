//
//  FormFieldFlag.swift
//  ForPDA
//
//  Created by Xialtal on 28.02.26.
//

public struct FormFieldFlag: OptionSet, Sendable, Equatable, Hashable {
    public var rawValue: Int
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }
    
    public static let required = FormFieldFlag(rawValue: 1 << 0)
    public static let uploadable = FormFieldFlag(rawValue: 1 << 1)
}
