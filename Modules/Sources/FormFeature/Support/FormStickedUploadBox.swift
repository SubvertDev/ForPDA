//
//  FormStickedUploadBox.swift
//  ForPDA
//
//  Created by Xialtal on 2.03.26.
//
   
public struct FormStickedUploadBox: Equatable {
    public let id: Int
    public let allowedExtensions: [String]
    
    public init(id: Int, allowedExtensions: [String]) {
        self.id = id
        self.allowedExtensions = allowedExtensions
    }
}
