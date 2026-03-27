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
    
    public static func parse(from string: String) throws(ParsingError) -> DeviceSpecificationsResponse {
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
        
        return DeviceSpecificationsResponse(
            tag: tag,
            type: DeviceType(rawValue: type) ?? .unknown,
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
    
    // MARK: - Images
    
    private static func parseDeviceImages(_ imagesRaw: [[Any]]) throws(ParsingError) -> [DeviceSpecificationsResponse.DeviceImage] {
        var images: [DeviceSpecificationsResponse.DeviceImage] = []
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
    
    // MARK: - Editions
    
    private static func parseDeviceEditions(_ editionsRaw: [[Any]]) throws(ParsingError) -> [DeviceSpecificationsResponse.Edition] {
        var editions: [DeviceSpecificationsResponse.Edition] = []
        for edition in editionsRaw {
            guard let subTag = edition[safe: 0] as? String,
                  let name = edition[safe: 1] as? String else {
                throw ParsingError.failedToCastFields
            }
            
            editions.append(.init(name: name, subTag: subTag))
        }
        return editions
    }
    
    // MARK: - Specifications
    
    private static func parseDeviceSpecifications(_ specsRaw: [[Any]]) throws(ParsingError) -> [DeviceSpecificationsResponse.Specification] {
        var specs: [DeviceSpecificationsResponse.Specification] = []
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
