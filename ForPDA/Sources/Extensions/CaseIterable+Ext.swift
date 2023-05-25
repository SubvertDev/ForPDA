//
//  CaseIterable+Ext.swift
//  ForPDA
//
//  Created by Subvert on 21.05.2023.
//

extension CaseIterable where Self: Equatable {
    func ordinal() -> Self.AllCases.Index {
        return Self.allCases.firstIndex(of: self)!
    }
}
