//
//  ArticleVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Nuke
import NukeExtensions
import SwiftyGif
import SwiftSoup
import YouTubeiOSPlayerHelper
import MarqueeLabel
import SwiftRichString
import SwiftMessages

final class ArticleVC: PDAViewController<ArticleView> {
    
    // MARK: - Properties
    
    private let article: Article
    private var texts = [String]()
    private var buttonUrl: String?
    
    var articleDocument: Document?
    
    private var viewModel: ArticleVM!
    
    // MARK: - Lifecycle
    
    init(article: Article) {
        self.article = article
        super.init()
        self.viewModel = ArticleVM(view: self)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        
        let label = MarqueeLabel(frame: .zero, rate: 30, fadeLength: 0)
        label.text = article.title
        label.fadeLength = 30
        navigationItem.titleView = label
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "ellipsis"), style: .plain,
                                                            target: self, action: #selector(threeDotsTapped))
        
        NukeExtensions.loadImage(with: URL(string: article.imageUrl)!, into: myView.articleImage)
        
        myView.titleLabel.text = article.title
        myView.commentsLabel.text = "Комментарии (\(article.commentAmount)):"
        let url = URL(string: article.url)!
        viewModel.loadArticle(url: url)
    }
    
    // MARK: - Actions
    
    @objc private func threeDotsTapped() {
        UIPasteboard.general.string = article.url
        SwiftMessages.show {
            let view = MessageView.viewFromNib(layout: .centeredView)
            view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
            view.configureDropShadow()
            view.configureContent(title: "Скопировано", body: self.article.url)
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            view.button?.isHidden = true
            return view
        }
    }
    
    // MARK: - Functions
    
    private func addComments(from page: Document) {
        let commentsVC = CommentsVC()
        commentsVC.article = article
        commentsVC.articleDocument = page
        addChild(commentsVC)
        myView.commentsContainer.addSubview(commentsVC.view)
        commentsVC.view.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        commentsVC.didMove(toParent: self)
    }
    
    func configureArticle(_ elements: [ArticleElement]) {
        myView.hideView.isHidden = true
        // addComments()
        
        for element in elements {
            switch element {
            case let item as TextElement:
                addLabel(text: item.text,
                         isHeader: item.isHeader,
                         isQuote: item.isQuote,
                         inList: item.inList,
                         countedListIndex: item.countedListIndex)
            case let item as ImageElement:
                addImage(url: item.url)
            case let item as VideoElement:
                addVideo(id: item.url)
            case let item as GifElement:
                addGif(url: item.url)
            case let item as ButtonElement:
                addButton(text: item.text, url: item.url)
            case let item as CharacteristicsElement:
                addCharters(chars: item.elements)
            default:
                break
            }
        }
        unhide()
    }
    
    func configureComments(from page: Document) {
        addComments(from: page)
    }
    
    // MARK: - Labels
    
    private func addLabel(text: String, isHeader: Bool, isQuote: Bool, inList: Bool, countedListIndex: Int) {
        var newText = text
        if newText.contains("<!--more-->") { newText.removeLast(11) }
        if newText.contains("&nbsp;") { newText = newText.replacingOccurrences(of: "&nbsp;", with: " ") }
        newText = newText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if newText.count == 0 { return }
        if inList { newText = "• \(newText)"}
        if countedListIndex > 0 { newText = "\(countedListIndex). \(newText)" }
        
        let ranges = text.indicesOf(string: "href=\"//")
        for range in ranges.reversed() {
            newText.insert(contentsOf: "https:", at: newText.index(newText.startIndex, offsetBy: range + 6))
        }
        
        let baseStyle = Style {
            $0.font = SystemFonts.HelveticaNeue.font(size: 17)
            // $0.hyphenationFactor = 0 // not working anymore?
            $0.alignment = .justified
        }
        let style = StyleXML(base: baseStyle, [:])
        let attrText = newText.set(style: style)
        let textView = PDAResizingTextView()
        let insets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        textView.textContainerInset = insets
        textView.attributedText = attrText
        textView.textColor = .label
        // textView.textContainer.lineFragmentPadding = 0
                
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
            
            DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(stack) }
        } else if isHeader {
            let baseStyle = Style {
                $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 20)
                $0.hyphenationFactor = 1
            }
            let style = StyleXML(base: baseStyle, [:])
            let attrText = newText.set(style: style)
            textView.attributedText = attrText
            DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(textView) }
        } else {
            DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(textView) }
        }
    }
    
    // MARK: - Characteristics
    
    private func addCharters(chars: [Charter]) {
        let mainStackView = UIStackView()
        mainStackView.axis = .vertical
        mainStackView.distribution = .fill
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 0, leading: 12, bottom: 0, trailing: 12)
        
        for char in chars {
            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.distribution = .fill
            
            let leftLabel = PDACharterLabel(text: char.title, type: .left)
            leftLabel.snp.makeConstraints { make in
                make.width.equalTo(UIScreen.main.bounds.width / 3)
            }
            stackView.addArrangedSubview(leftLabel)
            
            var text = ""
            for desc in char.description { text += desc + "\n" }
            text.removeLast()
            let rightLabel = PDACharterLabel(text: text, type: .right)
            stackView.addArrangedSubview(rightLabel)
            
            mainStackView.addArrangedSubview(stackView)
        }
        DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(mainStackView) }
    }
    
    // MARK: - Images
    
    private func addImage(url: String) {
        let imageView = PDAResizingImageView()
        NukeExtensions.loadImage(with: URL(string: url)!, into: imageView)
        DispatchQueue.main.async {
            self.myView.stackView.addArrangedSubview(imageView)
        }
    }
    
    // MARK: - Gifs

    private func addGif(url: String) {
        let imageView = PDAResizingImageView()
        imageView.setGifFromURL(URL(string: url)!)
        DispatchQueue.main.async {
            self.myView.stackView.addArrangedSubview(imageView)
        }
    }
    
    // MARK: - Videos
    
    private func addVideo(id: String) {
        let player = YTPlayerView(frame: .zero)
        player.load(withVideoId: id)
        player.snp.makeConstraints { make in
            make.height.equalTo(player.snp.width).multipliedBy(0.5625)
        }
        DispatchQueue.main.async {
            self.myView.stackView.addArrangedSubview(player)
        }
    }
    
    // MARK: - Buttons
    
    private func addButton(text: String, url: String) {
        buttonUrl = url
        let button = UIButton(type: .system)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        button.setTitle(text, for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 10
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        button.addTarget(self, action: #selector(self.buttonTapped), for: .touchUpInside)
        
        let container = UIView()
        container.addSubview(button)
        
        button.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.height.equalTo(44)
            make.top.bottom.equalToSuperview()
        }
        
        DispatchQueue.main.async {
            self.myView.stackView.addArrangedSubview(container)
        }
    }
    
    // MARK: - Actions
    
    @objc private func buttonTapped() {
        if let buttonUrl, let url = URL(string: buttonUrl) {
            UIApplication.shared.open(url)
        }
    }
    
    private func unhide() {
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
//            self.myView.hideView.isHidden = true
//            self.addComments()
//        }
    }
}
