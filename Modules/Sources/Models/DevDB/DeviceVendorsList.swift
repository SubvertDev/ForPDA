//
//  DeviceBrands.swift
//  ForPDA
//
//  Created by Xialtal on 3.04.26.
//

public struct DeviceVendorsList: Sendable, Equatable {
    public let type: DeviceType
    public let typeName: String
    public let vendors: [VendorInfo]
    
    public var actualCount: Int {
        return vendors.count(where: { $0.isActual })
    }
    
    public struct VendorInfo: Sendable, Equatable, Identifiable {
        public let tag: String
        public let name: String
        public let devicesCount: Int
        public let isActual: Bool
        
        public var id: String {
            return tag
        }
        
        public init(
            tag: String,
            name: String,
            devicesCount: Int,
            isActual: Bool
        ) {
            self.tag = tag
            self.name = name
            self.devicesCount = devicesCount
            self.isActual = isActual
        }
    }
    
    public init(
        type: DeviceType,
        typeName: String,
        brands: [VendorInfo]
    ) {
        self.type = type
        self.typeName = typeName
        self.vendors = brands
    }
}

public extension DeviceVendorsList {
    static let mock = DeviceVendorsList(
        type: .phone,
        typeName: "Смартфоны",
        brands: [
            .init(
                tag: "apple",
                name: "Apple",
                devicesCount: 17,
                isActual: true
            ),
            .init(
                tag: "xiaomi",
                name: "Xiaomi",
                devicesCount: 9,
                isActual: true
            ),
            .init(
                tag: "alcatel",
                name: "Alcatel",
                devicesCount: 12,
                isActual: false
            )
        ]
    )
}
