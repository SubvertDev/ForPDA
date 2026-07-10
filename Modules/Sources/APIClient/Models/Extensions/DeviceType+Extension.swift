//
//  DeviceType+Extension.swift
//  ForPDA
//
//  Created by Xialtal on 2.04.26.
//

import PDAPI
import Models

extension DeviceType {
    var transferType: DeviceCommand.DeviceType {
        switch self {
        case .phone: .phone
        case .ebook: .ebook
        case .pad: .pad
        case .smartWatch: .smartWatch
        }
    }
}
