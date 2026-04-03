//
//  DevDBParser.swift
//  ForPDA
//
//  Created by Xialtal on 14.12.25.
//

import Foundation
import Models

public struct DevDBParser {
    
    // MARK: - Device Specs Response
    
    public static func parse(from string: String) throws(ParsingError) -> DeviceSpecifications {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let type = array[safe: 2] as? String,
              let categoryName = array[safe: 3] as? String,
              let tag = array[safe: 4] as? String,
              let vendorName = array[safe: 5] as? String,
              let deviceName = array[safe: 6] as? String,
              let editionName = array[safe: 7] as? String,
              let editionsRaw = array[safe: 8] as? [[Any]],
              let imagesRaw = array[safe: 9] as? [[Any]],
              let specsRaw = array[safe: 10] as? [[Any]],
              let isMyDevice = array[safe: 11] as? Int else {
            throw ParsingError.failedToCastFields
        }
        
        return DeviceSpecifications(
            tag: tag,
            type: DeviceType(rawValue: type)!,
            vendorName: vendorName,
            deviceName: deviceName,
            editionName: editionName,
            categoryName: categoryName,
            images: try parseDeviceImages(imagesRaw),
            editions: try parseDeviceEditions(editionsRaw),
            specifications: try parseDeviceSpecifications(specsRaw),
            isMyDevice: isMyDevice == 1
        )
    }
    
    // MARK: - Device Vendor Response
    
    public static func parseDeviceVendor(from string: String) throws(ParsingError) -> DeviceVendor {
        guard let data = string.data(using: .utf8) else {
            throw ParsingError.failedToCreateDataFromString
        }
        
        guard let array = try? JSONSerialization.jsonObject(with: data, options: []) as? [Any] else {
            throw ParsingError.failedToCastDataToAny
        }
        
        guard let type = array[safe: 2] as? String,
              let categoryName = array[safe: 3] as? String,
              let name = array[safe: 5] as? String,
              let code = array[safe: 4] as? String,
              let productsRaw = array[safe: 6] as? [[Any]] else {
            throw ParsingError.failedToCastFields
        }
        
        return DeviceVendor(
            type: DeviceType(rawValue: type)!,
            name: name,
            code: code,
            categoryName: categoryName,
            products: try parseVendorProducts(productsRaw)
        )
    }
    
    // MARK: - Vendor Products
    
    private static func parseVendorProducts(_ productsRaw: [[Any]]) throws(ParsingError) -> [DeviceVendor.Product] {
        var products: [DeviceVendor.Product] = []
        for product in productsRaw {
            guard let tag = product[safe: 0] as? String,
                  let name = product[safe: 1] as? String,
                  let url = product[safe: 2] as? String,
                  let isActual = product[safe: 3] as? Int,
                  let entriesRaw = product[4] as? [[Any]] else {
                throw ParsingError.failedToCastFields
            }
            
            products.append(.init(
                tag: tag,
                name: name,
                imageUrl: URL(string: url)!,
                entries: try parseVendorProductEntry(entriesRaw),
                isActual: isActual != 0
            ))
        }
        return products
    }
    
    // MARK: - Vendor Product Entry
    
    private static func parseVendorProductEntry(_ entriesRaw: [[Any]]) throws(ParsingError) -> [DeviceVendor.Product.Entry] {
        var entries: [DeviceVendor.Product.Entry] = []
        for entry in entriesRaw {
            guard let name = entry[safe: 2] as? String,
                  let value = entry[safe: 4] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            entries.append(.init(name: name, value: value))
        }
        return entries
    }
    
    // MARK: - Specification Images
    
    private static func parseDeviceImages(_ imagesRaw: [[Any]]) throws(ParsingError) -> [DeviceSpecifications.DeviceImage] {
        var images: [DeviceSpecifications.DeviceImage] = []
        for image in imagesRaw {
            guard let isDeviceFront = image[safe: 0] as? Int,
                  let url = image[safe: 1] as? String,
                  let fullUrl = image[safe: 2] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            images.append(.init(
                url: URL(string: url)!,
                fullUrl: URL(string: fullUrl)!,
                isFront: isDeviceFront == 1
            ))
        }
        return images
    }
    
    // MARK: - Specification Editions
    
    private static func parseDeviceEditions(_ editionsRaw: [[Any]]) throws(ParsingError) -> [DeviceSpecifications.Edition] {
        var editions: [DeviceSpecifications.Edition] = []
        for edition in editionsRaw {
            guard let subTag = edition[safe: 0] as? String,
                  let name = edition[safe: 1] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            editions.append(.init(name: name, subTag: subTag))
        }
        return editions
    }
    
    // MARK: - Device Specifications
    
    private static func parseDeviceSpecifications(_ specsRaw: [[Any]]) throws(ParsingError) -> [DeviceSpecifications.Specification] {
        var specs: [DeviceSpecifications.Specification] = []
        for (index, spec) in specsRaw.enumerated() {
            guard let specType = spec[safe: 0] as? Int,
                  let title = spec[safe: 2] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            if specType == 0 { // category
                specs.append(.init(id: index, title: title, entries: []))
            } else {
                guard let value = spec[safe: 4] as? String else {
                    throw ParsingError.failedToCastFields
                }
                specs[specs.count - 1].entries.append(.init(name: title, value: value))
            }
        }
        return specs
    }
}
