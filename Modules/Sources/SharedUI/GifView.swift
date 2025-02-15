//
//  File.swift
//  
//
//  Created by Ilia Lubianoi on 22.05.2024.
//

import SwiftUI
import UIKit
import SwiftyGif

public struct GifView: UIViewRepresentable {
    
    private let url: URL
    
    public init(url: URL) {
        self.url = url
    }

    public func makeUIView(context: Context) -> UIImageView {
        let imageView = UIImageView(gifURL: self.url)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    public func updateUIView(_ uiView: UIImageView, context: Context) {
        uiView.setGifFromURL(self.url)
    }
}
