//
//  FormContentData.swift
//  ForPDA
//
//  Created by Xialtal on 25.05.25.
//

public enum FormContentData: Equatable {
    case text(String)
    case dropdown(Int, String)
    case uploadbox([File]) // TODO: ..
    case checkbox([Int: Bool])
    
    public struct File: Equatable {
        let id: Int
        let filename: String
        let uploadError: Bool
        let isRemoved: Bool
        let isUploading: Bool
    }
}
