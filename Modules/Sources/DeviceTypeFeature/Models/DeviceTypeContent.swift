//
//  DeviceTypeContent.swift
//  ForPDA
//
//  Created by Xialtal on 3.04.26.
//

import Models

public enum DeviceTypeContent: Equatable {
    case index
    case vendorsList(DeviceType)
    case vendor(String, type: DeviceType)
}
