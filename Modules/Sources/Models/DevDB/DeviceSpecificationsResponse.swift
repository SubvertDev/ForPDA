//
//  DeviceSpecificationsResponse.swift
//  ForPDA
//
//  Created by Xialtal on 14.12.25.
//

import Foundation

public struct DeviceSpecificationsResponse: Sendable, Equatable {
    public let tag: String
    public let type: DeviceType
    public let vendorName: String
    public let deviceName: String
    public let editionName: String
    public let categoryName: String
    public let images: [DeviceImage]
    public let editions: [Edition]
    public let specifications: [Specification]
    public let isMyDevice: Bool
    
    public struct DeviceImage: Sendable, Equatable {
        public let url: URL
        public let fullUrl: URL
        public let isFront: Bool
        
        public init(url: URL, fullUrl: URL, isFront: Bool) {
            self.url = url
            self.fullUrl = fullUrl
            self.isFront = isFront
        }
    }
    
    public struct Edition: Sendable, Equatable {
        public let name: String
        public let subTag: String
        
        public init(name: String, subTag: String) {
            self.name = name
            self.subTag = subTag
        }
    }
    
    public struct Specification: Sendable, Equatable {
        public let id: Int
        public let title: String
        public var entries: [SpecificationEntry]
        
        public struct SpecificationEntry: Sendable, Equatable {
            public let name: String
            public let value: String
            
            public init(name: String, value: String) {
                self.name = name
                self.value = value
            }
        }
        
        public init(id: Int, title: String, entries: [SpecificationEntry]) {
            self.id = id
            self.title = title
            self.entries = entries
        }
    }
    
    public init(
        tag: String,
        type: DeviceType,
        vendorName: String,
        deviceName: String,
        editionName: String,
        categoryName: String,
        images: [DeviceImage],
        editions: [Edition],
        specifications: [Specification],
        isMyDevice: Bool
    ) {
        self.tag = tag
        self.type = type
        self.vendorName = vendorName
        self.deviceName = deviceName
        self.editionName = editionName
        self.categoryName = categoryName
        self.images = images
        self.editions = editions
        self.specifications = specifications
        self.isMyDevice = isMyDevice
    }
}

public extension DeviceSpecificationsResponse {
    static let mock = DeviceSpecificationsResponse(
        tag: "apple",
        type: .phone,
        vendorName: "Apple",
        deviceName: "iPhone 13",
        editionName: "Edition",
        categoryName: "Смартфоны",
        images: [
            .init(
                url: URL(string: "https://4pda.to/static/img/db/img61570d87d79de1.70561421p.jpg?_=1633095064")!,
                fullUrl: URL(string: "https://4pda.to/static/img/db/img61570d87d79de1.70561421n.jpg?_=1633095064")!,
                isFront: true
            ),
            .init(
                url: URL(string: "https://4pda.to/static/img/db/img61570d889f0d21.00610039p.jpg?_=1633095076")!,
                fullUrl: URL(string: "https://4pda.to/static/img/db/img61570d889f0d21.00610039n.jpg?_=1633095076")!,
                isFront: false
            )
        ],
        editions: [
            .init(
                name: "pro",
                subTag: "iPhone 13 Pro"
            )
        ],
        specifications: [
            .init(
                id: 0,
                title: "Общее",
                entries: [
                    .init(name: "Производитель:", value: "Apple"),
                    .init(name: "Модель:", value: "iPhone 13"),
                    .init(name: "Операционная система:", value: "iOS 15, iOS 16, iOS 17, iOS 18")
                ]
            ),
            .init(
                id: 17,
                title: "Коммуникации",
                entries: [
                    .init(name: "Bluetooth:", value: "5.0"),
                    .init(
                        name: "Телефон:",
                        value: "5G , GSM (850, 900, 1800, 1900), LTE (700 (12/17/28), 800 (20), 850 (5/26), 900 (8)..."
                    )
                ]
            )
        ],
        isMyDevice: true
    )
}
