//
//  FormFieldConformable.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

protocol FormFieldConformable: Identifiable {
    var flag: Int { get }
    var isRequired: Bool { get }
    
    func isValid() -> Bool
    func getValue() -> String
}

extension FormFieldConformable {
    var isRequired: Bool {
        return flag & 1 != 0
    }
}
