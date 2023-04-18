//
//  DocumentParser.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//
//  swiftlint:disable force_try cyclomatic_complexity function_body_length
//  todo disable disables?

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
    let description: String?
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

struct CharacteristicsElement: ArticleElement {
    let elements: [Charter]
}

struct Charter {
    var title: String
    var description: [String]
}

final class DocumentParser {
    
    static let shared = DocumentParser()
    
    private init() {}
    
    // MARK: - Articles
    
    func parseArticles(from document: Document) -> [Article] {
        var articles = [Article]()
        
        let articleElements = try! document.select("article")
        for article in articleElements {
            // first three may be an advertisement
            // guard (3...).contains(index) else { continue }
            
            var isReview = false
            let type = try! article.attr("class")
            if type.components(separatedBy: " ").count == 3 { isReview = true }
            
            let title = try! article.select("[itemprop=name]").text()
            
            guard !title.isEmpty else { continue }
            
            let url = try! article.select("[rel=bookmark]").attr("href")
            let description = try! article.select("[itemprop=description]").text()
            let imageUrl = try! article.select("img").get(0).attr("src")
            let author = try! article.select("[class=autor]").select("a").text()
            let date = try! article.select("[class=date]").text()
            let commentAmount = try! article.select("[class=v-count]").text()
            
            let article = Article(url: url,
                                  title: title,
                                  description: description,
                                  imageUrl: imageUrl,
                                  author: author,
                                  date: date,
                                  isReview: isReview,
                                  commentAmount: commentAmount)
            
            articles.append(article)
        }
        return articles
    }
    
    // MARK: - Article
    
    func parseArticle(from document: Document) -> [ArticleElement] {
        if try! !document.select("[class=content-box]").isEmpty() {
            return parseArticleNormal(from: document)
        } else if try! !document.select("[class=article]").isEmpty() {
            return parseArticleFancy(from: document)
        } else {
            return []
        }
    }
    
    // MARK: - Article (normal)
    
    func parseArticleNormal(from document: Document) -> [ArticleElement] {
        var articleElements: [ArticleElement] = []
        let elements = try! document.select("[class=content-box]").select("p, h2, li, ol, dl, ul")
        
        for element in elements {
            if try! element.iS("[style=text-align:justify]") || (try! element.iS("[style=text-align: justify;]")) {
                let text = try! element.html()
                
                if let quote = try! element.parent()?.iS("blockquote"), quote {
                    articleElements.append(TextElement(text: text, isQuote: true))
                } else if try! element.iS("h2") {
                    try! element.select("br").remove()
                    let text = try! element.html()
                    articleElements.append(TextElement(text: text, isHeader: true))
                } else if let inList = try! element.parent()?.iS("ul"), inList {
                    articleElements.append(TextElement(text: text, inList: true))
                } else {
                    articleElements.append(TextElement(text: text))
                }
                
            } else if try! element.iS("ol") {
                let elements = try! element.select("li")
                for (index, element) in elements.enumerated() {
                    let text = try! element.html()
                    articleElements.append(TextElement(text: text, countedListIndex: index + 1))
                }
            } else if try! element.iS("[style=text-align:center]") || (try! element.iS("[style=text-align: center;]")) {
                
                var imageUrl = try! element.select("img").attr("src")
                if !imageUrl.isEmpty {
                    let images = try! element.select("img[alt]") // a[title] for high res
                    for image in images {
                        var url = try! image.attr("src")
                        if !url.contains("https:") { url = "https:" + url }
                        if url.suffix(3) == "jpg" || url.suffix(3) == "png" {
                            let text = try! element.select("[class=wp-caption-dd]").text()
                            let description = text.isEmpty ? nil : text
                            articleElements.append(ImageElement(url: url, description: description))
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
                            let text = try! element.select("a[class]").text() //.converted()
                            var url = try! element.select("a[class]").attr("href")
                            if !url.contains("https:") { url = "https:" + url }
                            articleElements.append(ButtonElement(text: text, url: url))
                        }
                        
                    } else {
                        imageUrl.removeFirst(24)
                        imageUrl.removeLast(7)
                        articleElements.append(VideoElement(url: imageUrl))
                    }
                }
            } else if try! element.iS("h2") {
                let text = try! element.text()
                articleElements.append(TextElement(text: text, isHeader: true))
            } else if try! element.iS("dl") {
                let charters = parseCharters(element)
                articleElements.append(CharacteristicsElement(elements: charters))
            } else if try! element.iS("ul") {
                let galCont = try! element.select("a[data-lightbox]")
                for gal in galCont {
                    var url = try! gal.attr("href")
                    if !url.contains("https:") { url = "https:" + url }
                    articleElements.append(ImageElement(url: url, description: nil))
                }
            }
        }
        return articleElements
    }
    
    // MARK: - Article (fancy)
    
    func parseArticleFancy(from document: Document) -> [ArticleElement] {
        var articleElements: [ArticleElement] = []
        let elements = try! document.select("[class=article]").select("p, h2, h3, figure, dl, a[class]")
        
        for element in elements {
            if try! element.iS("p") {
                let text = try! element.text()
                articleElements.append(TextElement(text: text))
            } else if try! element.iS("h2") || (try! element.iS("h3")) {
                try! element.select("br").remove()
                let text = try! element.html()
                articleElements.append(TextElement(text: text, isHeader: true))
            } else if try! element.iS("figure") {
                let images = try! element.select("img[alt]")
                for image in images {
                    var url = try! image.attr("src")
                    if !url.contains("https:") { url = "https:" + url }
                    if url.suffix(3) == "jpg" || url.suffix(3) == "png" {
                        let text = try! element.select("[class=wp-caption-dd]").text()
                        let description = text.isEmpty ? nil : text
                        articleElements.append(ImageElement(url: url, description: description))
                    } else if url.suffix(3) == "gif" {
                        articleElements.append(GifElement(url: url))
                    }
                }
            } else if try! element.iS("dl") {
                let charters = parseCharters(element)
                articleElements.append(CharacteristicsElement(elements: charters))
            } else if try! element.iS("a") {
                let text = try! element.text()
                let url = try! element.attr("href")
                articleElements.append(ButtonElement(text: text, url: url))
            }
        }
        return articleElements
    }
    
    private func parseCharters(_ element: Element) -> [Charter] {
        var charterElements: [Charter] = []
        let elements = try! element.select("dd, dt")
        
        var charter = Charter(title: "", description: [])
        
        for element in elements {
            if try! element.iS("dt") {
                charter.title = try! element.text()
            } else if try! element.iS("dd") {
                let text = try! element.text()
                if text.contains("<br>") {
                    let splitted = text.components(separatedBy: "<br>")
                    for split in splitted {
                        charter.description.append(split)
                    }
                } else {
                    charter.description.append(text)
                }
                charterElements.append(charter)
                charter = Charter(title: "", description: [])
            }
        }
        return charterElements
    }
    
    // MARK: - Comments
    
    func parseComments(from document: Document) -> [Comment] {
        let commentList = try! document.select("ul[class=comment-list level-0").select("li[data-author-id]")
        return recurseComments(commentList: commentList, level: 0)
    }
    
    private func recurseComments(commentList: Elements, level: Int) -> [Comment] {
        var allComments = [Comment]()
        let newComments = Elements()
        
        for comments in commentList {
            let parentElement = comments.parent()
            let isLeveled = try! parentElement?.iS("ul[class=comment-list level-\(level)]") ?? true
            if isLeveled { newComments.add(comments) }
        }
        
        for comments in newComments {
            let replies = try! comments.select("[class*=comment-list]").select("li[data-author-id]")
            if replies.count > 0 {
                let nextLevelList = try! comments.select("[class*=comment-list level-\(level + 1)]").select("li[data-author-id]")
                let replies = recurseComments(commentList: nextLevelList, level: level + 1)
                allComments.append(getCommentFromElement(comments, replies: replies, level: level))
            } else {
                if !comments.hasAttr("style") {
                    allComments.append(getCommentFromElement(comments, level: level))
                }
            }
        }
        return allComments
    }
    
    private func getCommentFromElement(_ element: Element, replies: [AbstractComment] = [], level: Int) -> Comment {
        try! element.select("ul[class*=comment-list]").remove()
        let commentType = try! element.select("div[id]").attr("class")
        guard commentType != "deleted" else {
            return Comment(author: "Неизвестно", text: "(Комментарий удален)", date: "", likes: 0, replies: replies, level: level)
        }
        let author = try! element.select("[class=nickname]").first()?.text() ?? "Error"
        let text = try! element.select("[class=content]").first()?.text() ?? "Error"
        let date = try! element.select("[class=date").first()?.text() ?? "0.0.0"
        
        let likes: Int
        if let likesAmount = try! element.select("[class=num]").first()?.text() {
            likes = Int(likesAmount) ?? 0
        } else {
            likes = 0
        }
        
        return Comment(author: author, text: text, date: date, likes: likes, replies: replies, level: level)
    }
    
}
