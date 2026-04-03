//
//  DeviceVendor.swift
//  ForPDA
//
//  Created by Xialtal on 2.04.26.
//

import Foundation

public struct DeviceVendor: Sendable, Equatable {
    public let type: DeviceType
    public let name: String
    public let code: String
    public let categoryName: String
    public let products: [Product]
    
    public var actualCount: Int {
        return products.count(where: { $0.isActual })
    }
    
    public struct Product: Sendable, Identifiable, Equatable {
        public let tag: String
        public let name: String
        public let imageUrl: URL
        public var entries: [Entry]
        public let isActual: Bool
        
        public var id: String {
            return tag
        }
        
        public struct Entry: Sendable, Equatable {
            public let name: String
            public let value: String
            
            public init(name: String, value: String) {
                self.name = name
                self.value = value
            }
        }
        
        public init(
            tag: String,
            name: String,
            imageUrl: URL,
            entries: [Entry],
            isActual: Bool
        ) {
            self.tag = tag
            self.name = name
            self.imageUrl = imageUrl
            self.entries = entries
            self.isActual = isActual
        }
    }
    
    public init(
        type: DeviceType,
        name: String,
        code: String,
        categoryName: String,
        products: [Product]
    ) {
        self.type = type
        self.name = name
        self.code = code
        self.categoryName = categoryName
        self.products = products
    }
}

public extension DeviceVendor {
    static let mock = DeviceVendor(
        type: .phone,
        name: "Apple",
        code: "apple",
        categoryName: "Смартфоны",
        products: [
            .init(
                tag: "apple_iphone_16e",
                name: "iPhone 16e",
                imageUrl: URL(string: "https://4pda.to/static/img/db/img6826433f673aa4.16450237p.jpg")!,
                entries: [
                    .init(name: "ОС:", value: "iOS 18"),
                    .init(name: "Процессор:", value: "Apple A18"),
                    .init(name: "Память:", value: "128/256/512 ГБ."),
                    .init(name: "Экран:", value: "Super Retina XDR OLED"),
                    .init(name: "Размер:", value: "6,1\" дюймов"),
                    .init(name: "Год выпуска:", value: "2025")
                ],
                isActual: true
            ),
            .init(
                tag: "apple_iphone_17_pro",
                name: "iPhone 17 Pro",
                imageUrl: URL(string: "https://4pda.to/static/img/db/img68e84609640ae6.18217003p.jpg")!,
                entries: [
                    .init(name: "ОС:", value: "iOS 26"),
                    .init(name: "Процессор:", value: "Apple A19 Pro"),
                    .init(name: "Память:", value: "256/512/1024 ГБ."),
                    .init(name: "Экран:", value: "LTPO Super Retina XDR OLED"),
                    .init(name: "Размер:", value: "6,3\" дюймов"),
                    .init(name: "Год выпуска:", value: "2025")
                ],
                isActual: true
            ),
            .init(
                tag: "apple_iphone_16",
                name: "iPhone 16",
                imageUrl: URL(string: "https://4pda.to/static/img/db/img673506cf586340.68404184p.jpg")!,
                entries: [
                    .init(name: "ОС:", value: "iOS 18"),
                    .init(name: "Процессор:", value: "Apple A18"),
                    .init(name: "Память:", value: "128/256/512/1024 ГБ."),
                    .init(name: "Экран:", value: "Super Retina XDR OLED"),
                    .init(name: "Размер:", value: "6,1\" дюймов"),
                    .init(name: "Год выпуска:", value: "2024")
                ],
                isActual: false
            ),
        ]
    )
}
