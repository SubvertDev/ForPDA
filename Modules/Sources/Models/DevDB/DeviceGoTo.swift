//
//  DeviceGoTo.swift
//  ForPDA
//
//  Created by Xialtal on 3.04.26.
//

public enum DeviceGoTo {
    case index
    case brands(DeviceType)
    case vendor(tag: String, type: DeviceType)
    case device(tag: String, subTag: String?)
}
