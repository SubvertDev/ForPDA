//
//  ParsingService.swift
//  ForPDA
//
//  Created by Subvert on 14.12.2022.
//
//  swiftlint:disable force_try cyclomatic_complexity function_body_length type_body_length file_length

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
    let url: URL
    let description: String?
    let width: Int
    let height: Int
}

struct VideoElement: ArticleElement {
    let url: String
}

struct GifElement: ArticleElement {
    let url: URL
    let width: Int
    let height: Int
}

struct ButtonElement: ArticleElement {
    let text: String
    let url: URL
}

struct BulletListParentElement: ArticleElement {
    let elements: [BulletListElement]
}

struct BulletListElement: Hashable {
    var title: String
    var description: [String]
}

final class ParsingService {
    
    // MARK: - Articles
    
    func parseArticles(from document: String) -> [Article] {
        let document = try! SwiftSoup.parse(document)
        
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
            
            let article = Article(
                url: url,
                info: ArticleInfo(
                    title: title,
                    description: description,
                    imageUrl: URL(string: imageUrl)!,
                    author: author,
                    date: date,
                    isReview: isReview,
                    commentAmount: commentAmount
                )
            )
            
            articles.append(article)
        }
        return articles
    }
    
    // MARK: - Article
    
    func parseArticle(from document: String) -> [ArticleElement] {
        let document = try! SwiftSoup.parse(document)

        if try! !document.select("[class=content-box]").isEmpty() {
            return parseArticleNormal(from: document)
        } else if try! !document.select("[class=article]").isEmpty() {
            return parseArticleFancy(from: document)
        } else {
            return []
        }
    }
    
    // MARK: - Article Info (deeplink case)
    
    func parseArticleInfo(from document: String) -> ArticleInfo {
        let document = try! SwiftSoup.parse(document)
        
        let author = try! document.select("[class=name]").text()
        let date = try! document.select("[class=date]").get(0).text()
        let commentAmount = try! document.select("[class=number]").text()
        
        var title = ""
        var imageUrl = ""
        if try! !document.select("[class=content-box]").isEmpty() {
            title = try! document.select("[itemprop=headline]").get(0).text()
            for element in try! document.select("[itemprop=image") where element.hasAttr("sizes") {
                imageUrl = try! element.attr("src")
                break
            }
        } else if try! !document.select("[class=article]").isEmpty() {
            title = try! document.select("[class=article-header]").select("h1").text()
            imageUrl = try! document.select("[class*=article]").attr("src")
            if !imageUrl.contains("https:") { imageUrl = "https:" + imageUrl }
        }
        
        let articleInfo = ArticleInfo(
            title: title,
            description: "",
            imageUrl: URL(string: imageUrl)!,
            author: author,
            date: date,
            isReview: false,
            commentAmount: commentAmount
        )
        
        return articleInfo
    }
    
    // MARK: - Article (normal)
    
    private func parseArticleNormal(from document: Document) -> [ArticleElement] {
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
                    guard text != "&nbsp;" else { continue }
                    articleElements.append(TextElement(text: text, isHeader: true))
                } else if let inList = try! element.parent()?.iS("ul"), inList {
                    articleElements.append(TextElement(text: text, inList: true))
                } else if let insideList = try! element.parent()?.iS("ol"), insideList {
                    continue
                } else {
                    guard text != "<!--more-->" else { continue }
                    guard text != "&nbsp;" else { continue }
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
                        let width = try! image.attr("width")
                        let height = try! image.attr("height")
                        if !url.contains("https:") { url = "https:" + url }
                        if url.suffix(3) == "jpg" || url.suffix(3) == "png" {
                            let text = try! element.select("[class=wp-caption-dd]").text()
                            let description = text.isEmpty ? nil : text
                            let imageElement = ImageElement(
                                url: URL(string: url)!,
                                description: description,
                                width: Int(width.trimmingCharacters(in: .letters))!,
                                height: Int(height.trimmingCharacters(in: .letters))!
                            )
                            articleElements.append(imageElement)
                        } else if url.suffix(3) == "gif" {
                            // Some gifs are not working when inside a[title] with working href inside it
                            // couldn't figure out how to get them and not kill .jpg parsing
                            let gifElement = GifElement(
                                url: URL(string: url)!,
                                width: Int(width.trimmingCharacters(in: .letters))!,
                                height: Int(height.trimmingCharacters(in: .letters))!
                            )
                            articleElements.append(gifElement)
                        }
                    }
                    
                } else {
                    imageUrl = try! element.select("iframe").attr("src")
                    if imageUrl.isEmpty {
                        if try! element.text() == " " || (try! element.text() == "") {
                            continue
                        } else {
                            var text = try! element.select("a[class]").text() //.converted()
                            var url = try! element.select("a[class]").attr("href")
                            if !url.contains("https:") { url = "https:" + url }
                            if try! document.html().contains("form action=") {
                                text = "Голосование на сайте"
                                url = try! document.select("meta[property=og:url]").attr("content")
                            }
                            let buttonElement = ButtonElement(
                                text: text,
                                url: URL(string: url)!
                            )
                            articleElements.append(buttonElement)
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
                let bulletList = parseBulletList(element)
                articleElements.append(BulletListParentElement(elements: bulletList))
            } else if try! element.iS("ul") {
                let galCont = try! element.select("a[data-lightbox]")
                for gal in galCont {
                    var url = try! gal.attr("href")
                    if !url.contains("https:") { url = "https:" + url }
                    let galInfo = try! gal.select("img[src]")
                    let width = try! galInfo.attr("width")
                    let height = try! galInfo.attr("height")
                    let imageElement = ImageElement(
                        url: URL(string: url)!,
                        description: nil,
                        width: Int(width.trimmingCharacters(in: .letters))!,
                        height: Int(height.trimmingCharacters(in: .letters))!
                    )
                    articleElements.append(imageElement)
                }
            }
        }
        return articleElements
    }
    
    // MARK: - Article (fancy)
    
    private func parseArticleFancy(from document: Document) -> [ArticleElement] {
        var articleElements: [ArticleElement] = []
        let elements = try! document.select("[class=article]").select("p, h2, h3, figure, dl, a[class]")
        
        for element in elements {
            if try! element.iS("p") {
                let text = try! element.text()
                if !text.isEmpty {
                    if try! !element.html().contains("btn") {
                        articleElements.append(TextElement(text: text))
                    } else {
                        continue
                    }
                } else if try! element.iS("[style=text-align:center]") || (try! element.iS("[style=text-align: center;]")) {
                    var imageUrl = try! element.select("iframe").attr("src")
                    if imageUrl.isEmpty {
                        if (try! element.text() == " ") || (try! element.text() == "") {
                            continue
                        } else {
                            var text = try! element.select("a[class]").text() //.converted()
                            var url = try! element.select("a[class]").attr("href")
                            if !url.contains("https:") { url = "https:" + url }
                            if try! document.html().contains("form action=") {
                                text = "Голосование на сайте"
                                url = try! document.select("meta[property=og:url]").attr("content")
                            }
                            let buttonElement = ButtonElement(
                                text: text,
                                url: URL(string: url)!
                            )
                            articleElements.append(buttonElement)
                        }
                    } else {
                        imageUrl.removeFirst(24)
                        imageUrl.removeLast(7)
                        articleElements.append(VideoElement(url: imageUrl))
                    }
                }
            } else if try! element.iS("h2") || (try! element.iS("h3")) {
                guard try! !element.text().isEmpty else { continue }
                try! element.select("br").remove()
                let text = try! element.html()
                articleElements.append(TextElement(text: text, isHeader: true))
            } else if try! element.iS("figure") {
                let images = try! element.select("img[alt]")
                for image in images {
                    // (todo) switch to srcset?
                    var url = try! image.attr("src")
                    let width = try! image.attr("width")
                    let height = try! image.attr("height")
                    if !url.contains("https:") { url = "https:" + url }
                    if url.suffix(3) == "jpg" || url.suffix(3) == "png" {
                        //
                        let srcset = try! image.attr("srcset")
                        url = srcset.components(separatedBy: ", ")[0].components(separatedBy: " ")[0]
                        //
                        let text = try! element.select("[class=wp-caption-dd]").text()
                        let description = text.isEmpty ? nil : text
                        let imageElement = ImageElement(
                            url: URL(string: url)!,
                            description: description,
                            width: Int(width.trimmingCharacters(in: .letters))!,
                            height: Int(height.trimmingCharacters(in: .letters))!
                        )
                        articleElements.append(imageElement)
                    } else if url.suffix(3) == "gif" {
                        let gifElement = GifElement(
                            url: URL(string: url)!,
                            width: Int(width.trimmingCharacters(in: .letters))!,
                            height: Int(height.trimmingCharacters(in: .letters))!
                        )
                        articleElements.append(gifElement)
                    }
                }
            } else if try! element.iS("dl") {
                let charters = parseBulletList(element)
                articleElements.append(BulletListParentElement(elements: charters))
            } else if try! element.iS("a") {
                var text = ""
                if element.children().count > 1 {
                    for textElement in element.children() {
                        text += try! textElement.text() + "\n"
                    }
                } else {
                    text = try! element.text()
                }
                let url = try! element.attr("href")
                let buttonElement = ButtonElement(
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines),
                    url: URL(string: url)!
                )
                articleElements.append(buttonElement)
            }
        }
        return articleElements
    }
    
    private func parseBulletList(_ element: Element) -> [BulletListElement] {
        var charterElements: [BulletListElement] = []
        let elements = try! element.select("dd, dt")
        
        var charter = BulletListElement(title: "", description: [])
        
        for element in elements {
            if try! element.iS("dt") {
                charter.title = try! element.text()
            } else if try! element.iS("dd") {
                let text = try! element.html()
                if text.contains("<br>") {
                    let splitted = text.components(separatedBy: "<br>")
                    for split in splitted {
                        charter.description.append(split.trimmingCharacters(in: .whitespaces))
                    }
                } else {
                    charter.description.append(text.trimmingCharacters(in: .whitespaces))
                }
                charterElements.append(charter)
                charter = BulletListElement(title: "", description: [])
            }
        }
        return charterElements
    }
    
    // MARK: - Comments
    
    func parseComments(from document: String) -> [Comment] {
        let document = try! SwiftSoup.parse(document)
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
            return Comment(
                avatarUrl: URL.defaultAvatar,
                author: "",
                text: "(Комментарий удален)",
                date: "",
                likes: 0,
                replies: replies,
                level: level
            )
        }
        
        let avatarUrl = try! element.select("[class=comment-avatar]").first()?.select("img[src]").attr("src") ?? ""
        
        let author = try! element.select("[class=nickname]").first()?.text() ?? ""
        
        var text: String
        if #available(iOS 16.0, *) {
            text = try! element.select("[class=content]").first()?.html() ?? ""
            text = stripHtmlFromComment(from: text)
        } else {
            text = try! element.select("[class=content]").first()?.text() ?? ""
        }
        text = text.replacingOccurrences(of: "&gt;", with: ">")
        
        let date = try! element.select("[class=date").first()?.text() ?? ""
        
        let likes: Int
        if let likesAmount = try! element.select("[class=num]").first()?.text() {
            likes = Int(likesAmount) ?? 0
        } else {
            likes = 0
        }
        
        return Comment(
            avatarUrl: URL(string: avatarUrl) ?? URL.defaultAvatar,
            author: author,
            text: text,
            date: date,
            likes: likes,
            replies: replies,
            level: level
        )
    }
    
    // MARK: - Captcha
    
    struct CaptchaResponse {
        let url: String
        let time: String
        let sig: String
    }
    
    func parseCaptcha(from htmlString: String) -> CaptchaResponse? {
        let document = try! SwiftSoup.parse(htmlString)
        
        if htmlString.contains("action=logout&k=") { return nil } // logged in
        
        let captchaTime = try! document.select("[name=captcha-time]").get(0).attr("value")
        let captchaSig = try! document.select("[name=captcha-sig]").get(0).attr("value")
        
        var linkElement = try! document.select("img[src]").get(0).attr("src")
        if !linkElement.contains("https:") { linkElement = "https:" + linkElement }
        
        return CaptchaResponse(url: linkElement, time: captchaTime, sig: captchaSig)
    }
    
    // MARK: - Login
    
    func parseLogin(from htmlString: String) -> (loggedIn: Bool, errorMessage: String?) {
        let document = try! SwiftSoup.parse(htmlString)
        
        let errors = try! document.select("[class=errors-list")
        let hasLogout = htmlString.contains("action=logout&k=")
        
        if !errors.isEmpty() {
            let error = try! errors.select("li").get(0).text()
            return (false, error)
        } else {
            if hasLogout {
                return (true, nil)
            } else {
                return (false, nil)
            }
        }
    }
    
    // MARK: - Is Logged In
    
    func parseIsLoggedIn(from htmlString: String) -> Bool {
        return htmlString.contains("action=logout&k=")
    }
    
    // MARK: - Auth Key
    
    func parseAuthKey(from htmlString: String) -> String? {
        let document = try! SwiftSoup.parse(htmlString)
                
        let authLink = try! document.select("a").select("[title=Выход]").attr("href")
        
        if let range = authLink.range(of: "k=([^&]+)", options: .regularExpression) {
            let authKey = String(authLink[range])
                .replacingOccurrences(of: "k=", with: "")
                .removingPercentEncoding
            return authKey
        } else {
            return nil
        }
    }
    
    // MARK: - User Id
    
    func parseUserId(from htmlString: String) -> String {
        let document = try! SwiftSoup.parse(htmlString)
        
        let showuserLink = try! document.select("a").select("[href*=showuser]").attr("href")
        let id = showuserLink.split(separator: "=").last!
        
        return String(id)
    }
    
    // MARK: - User
    
    func parseUser(from htmlString: String) -> User {
        let document = try! SwiftSoup.parse(htmlString)
        
        let userIdElement = try! document.select("a").select("[href*=showuser]").attr("href")
        let userId = String(userIdElement.removingPercentEncoding?.split(separator: "=").last ?? "2")
        let avatarUrl = try! document.select("img").select("[alt=Аватар]").attr("src")
        let nickname = try! document.select("h1").last()?.text() ?? "Ошибка"
        let title = try! document.select("span").select("[class=title]").get(0).text()
        let role = try! document.select("span").select("[style*=color]").text() // добавить цвет
        let registrationDate = try! document.select("div").select("[class=area]").get(0).text() // какой?
        let warningsAmount = try! document.select("div").select("[class=area]").get(1).text() //
        let lastVisitDate = try! document.select("div").select("[class=area]").get(2).text() // какой?
        let signature = try! document.select("div").select("[class=u-note]").text()
        
        return User(
            id: userId,
            avatarUrl: avatarUrl,
            nickname: nickname,
            title: title,
            role: role,
            registrationDate: registrationDate,
            warningsAmount: warningsAmount,
            lastVisitDate: lastVisitDate,
            signature: signature
        )
    }
    
    // MARK: - Helper Methods
    
    @available(iOS 16.0, *)
    private func stripHtmlFromComment(from comment: String) -> String {
        let htmlRegex = /<(?!br)[^>]*>/
        let strippedHTMLExceptBr = comment.replacing(htmlRegex, with: "")
        let brRegex = /\s*<br>\s*/
        return strippedHTMLExceptBr.replacing(brRegex, with: "\n")
    }
}
