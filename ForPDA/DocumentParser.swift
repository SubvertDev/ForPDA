//
//  DocumentParser.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//

import Foundation
import SwiftSoup

protocol ArticleElement {}

struct TextElement: ArticleElement {
    let text: String
    let isHeader: Bool
    let isQuote: Bool
    let inList: Bool
    let countedListIndex: Int
    
    init(text: String,
         isHeader: Bool = false,
         isQuote: Bool = false,
         inList: Bool = false,
         countedListIndex: Int = 0) {
        self.text = text
        self.isHeader = isHeader
        self.isQuote = isQuote
        self.inList = inList
        self.countedListIndex = countedListIndex
    }
}

struct ImageElement: ArticleElement {
    let url: String
}

struct VideoElement: ArticleElement {
    let url: String
}

struct GifElement: ArticleElement {
    let url: String
}

struct ButtonElement: ArticleElement {
    let text: String
    let url: String
}

final class DocumentParser {
    
    static let shared = DocumentParser()
        
    private init() {}
    
    func parseArticles(from document: Document) -> [ArticleElement] {
        // print(document)
        var articleElements: [ArticleElement] = []
        
        let elements = try! document.select("[class=content-box]").select("p, h2, li, ol")

        for element in elements {
            if try! element.iS("[style=text-align:justify]") || (try! element.iS("[style=text-align: justify;]")) {
                let text = try! element.html().converted()
                
                if let quote = try! element.parent()?.iS("blockquote"), quote {
                    articleElements.append(TextElement(text: text, isQuote: true))
                } else if try! element.iS("h2") {
                    try! element.select("br").remove()
                    let text = try! element.html().converted()
                    articleElements.append(TextElement(text: text, isHeader: true))
                } else if let inList = try! element.parent()?.iS("ul"), inList {
                    articleElements.append(TextElement(text: text, inList: true))
                } else {
                    articleElements.append(TextElement(text: text))
                }

            } else if try! element.iS("ol") {
                let elements = try! element.select("li")
                for (index, element) in elements.enumerated() {
                    let text = try! element.html().converted()
                    articleElements.append(TextElement(text: text, countedListIndex: index + 1))
                }
            } else if try! element.iS("[style=text-align:center]") || (try! element.iS("[style=text-align: center;]")) {

                var imageUrl = try! element.select("img").attr("src")
                if !imageUrl.isEmpty {
                    let images = try! element.select("img[alt]") // a[title] for high res
                    for image in images {
                        var url = try! image.attr("src")
                        url = "https:" + url
                        if url.suffix(3) == "jpg" || url.suffix(3) == "png" {
                            articleElements.append(ImageElement(url: url))
                        } else if url.suffix(3) == "gif" {
                            articleElements.append(GifElement(url: url))
                        }
                    }
                    
                } else {
                    imageUrl = try! element.select("iframe").attr("src")
                    if imageUrl.isEmpty {
                        if try! element.text() == " " {
                            continue
                        } else {
                            let text = try! element.select("a[class]").text().converted()
                            var url = try! element.select("a[class]").attr("href")
                            url = "https:" + url
                            articleElements.append(ButtonElement(text: text, url: url))
                        }
                        
                    } else {
                        imageUrl.removeFirst(24)
                        imageUrl.removeLast(7)
                        articleElements.append(VideoElement(url: imageUrl))
                    }
                }
            } else if try! element.iS("h2") {
                let text = try! element.text().converted()
                articleElements.append(TextElement(text: text, isHeader: true))
            } else {
                continue
            }
        }
        return articleElements
    }
    
}
