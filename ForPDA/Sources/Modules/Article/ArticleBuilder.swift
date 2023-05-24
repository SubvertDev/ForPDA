//
//  ArticleBuilder.swift
//  ForPDA
//
//  Created by Subvert on 24.05.2023.
//
//  swiftlint:disable function_parameter_count

import UIKit
import SwiftyGif
import NukeExtensions
import SwiftRichString
import YouTubePlayerKit

final class ArticleBuilder {
    
    // MARK: - Default
    
    static func makeDefaultArticle(description: String, url: String) -> [ArticleElement] {
        var description = description
        if description.contains("Узнать подробнее") { description.removeLast(16) }
        return [
            TextElement(text: description),
            ButtonElement(text: R.string.localizable.learnMore(), url: url)
        ]
    }
    
    // MARK: - Labels
    
    /// Returns either PDAResizingTextView or StackView with that textview inside
    static func addLabel(text: String, isHeader: Bool, isQuote: Bool, inList: Bool, countedListIndex: Int, delegate: PDAResizingTextViewDelegate) -> UIView? {
        var newText = text
        if newText.contains("<!--more-->") { newText = newText.replacingOccurrences(of: "<!--more-->", with: "") }
        if newText.contains("<br>") { newText = newText.replacingOccurrences(of: "<br>", with: "") }
        if newText.contains("&nbsp;") { newText = newText.replacingOccurrences(of: "&nbsp;", with: " ") }
        newText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if newText.count == 0 { return nil }
        if inList { newText = "• \(newText)"}
        if countedListIndex > 0 { newText = "\(countedListIndex). \(newText)" }
        
        let ranges = text.indicesOf(string: "href=\"//")
        for range in ranges.reversed() {
            newText.insert(contentsOf: "https:", at: newText.index(newText.startIndex, offsetBy: range + 6))
        }
        
        let baseStyle = Style {
            $0.font = SystemFonts.HelveticaNeue.font(size: 17)
            $0.hyphenationFactor = 1
            $0.alignment = .justified
        }
        
        let style = StyleXML(base: baseStyle, [:])
        let attrText = newText.set(style: style)
        let textView = PDAResizingTextView()
        textView.myDelegate = delegate
        let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        textView.textContainerInset = insets
        textView.attributedText = attrText
        textView.textColor = .label
                
        if isQuote {
            let stack = UIStackView()
            stack.axis = .horizontal
            stack.distribution = .fill
            stack.spacing = 12
            
            let view = UIView()
            view.backgroundColor = .systemGray
            view.snp.makeConstraints { $0.width.equalTo(5) }
            
            stack.addArrangedSubview(view)
            stack.addArrangedSubview(textView)
            
            return stack
            
        } else if isHeader {
            let baseStyle = Style {
                $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 20)
                $0.hyphenationFactor = 1
            }
            let style = StyleXML(base: baseStyle, [:])
            let attrText = newText.set(style: style)
            textView.attributedText = attrText
            textView.textColor = .label
            return textView
        } else {
            return textView
        }
    }
    
    // MARK: - Bullet List
    
    /// Returns StackView
    static func addBulletList(bulletList: [BulletListElement]) -> UIView {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        
        for bullet in bulletList {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fill
            
            let leftLabel = PDABulletLabel(text: bullet.title, type: .left)
            leftLabel.snp.makeConstraints { make in
                make.width.equalTo(UIScreen.main.bounds.width / 3)
            }
            stackView.addArrangedSubview(leftLabel)
            
            var text = ""
            for desc in bullet.description { text += desc + "\n" }
            text.removeLast()
            let rightLabel = PDABulletLabel(text: text, type: .right)
            stackView.addArrangedSubview(rightLabel)
            
            mainStackView.addArrangedSubview(stackView)
        }
        return mainStackView
    }
    
    // MARK: - Images
    
    /// Returns PDAResizingImageView or PDAResizingImageViewWithText if has description text
    @MainActor static func addImage(url: String, description: String?) -> UIView {
        // todo make one view?
        if let description {
            let view = PDAResizingImageViewWithText(description)
            let imageOptions = ImageLoadingOptions(placeholder: UIImage(named: "placeholder"))
            NukeExtensions.loadImage(with: URL(string: url), options: imageOptions, into: view.imageView) { _ in }
            return view
        } else {
            let view = PDAResizingImageView()
            let imageOptions = ImageLoadingOptions(placeholder: UIImage(named: "placeholder"))
            NukeExtensions.loadImage(with: URL(string: url), options: imageOptions, into: view) { _ in }
            return view
        }
    }
    
    // MARK: - Gifs

    /// Returns PDAResizingImageView
    static func addGif(url: String) -> UIView {
        let imageView = PDAResizingImageView()
        imageView.setGifFromURL(URL(string: url)!)
        return imageView
    }
    
    // MARK: - Videos
    
    /// Returns YouTubePlayerViewController's view
    static func addVideo(id: String) -> UIView {
        let player = YouTubePlayerViewController(source: .video(id: id))
        player.view.snp.makeConstraints { make in
            make.height.equalTo(player.view.snp.width).multipliedBy(Double(9)/16)
        }
        return player.view
    }
    
    // MARK: - Buttons
    
    /// Returns UIView container with UIButton inside
    static func addButton(text: String, url: String, completion: @escaping () -> Void) -> UIView {
        let action = UIAction { _ in completion() }
        let button = UIButton(type: .system, primaryAction: action)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
                
        let container = UIView()
        container.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
            make.top.bottom.equalToSuperview()
        }
        
        return container
    }
    
}
