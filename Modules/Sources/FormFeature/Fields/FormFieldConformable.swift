//
//  FormFieldConformable.swift
//  FormFeature
//
//  Created by Ilia Lubianoi on 20.07.2025.
//

import Models

protocol FormFieldConformable: Identifiable {
    var flag: FormFlag { get }
    var isRequired: Bool { get }
    
    func isValid() -> Bool
    func getValue() -> FormValue
}

extension FormFieldConformable {
    var isRequired: Bool {
        return flag.contains(.required)
    }
}
