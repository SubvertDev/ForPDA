//
//  ArticleVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//
//  swiftlint:disable type_body_length

import UIKit
import Nuke
import NukeExtensions
import SwiftyGif
import SwiftSoup
import YouTubePlayerKit
import MarqueeLabel
import SwiftRichString
import SwiftMessages
import Factory
import SFSafeSymbols

protocol ArticleVCProtocol: AnyObject {
    func configureArticle(with elements: [ArticleElement])
    func configureComments(from page: String)
    func showError()
}

final class ArticleVC: PDAViewController<ArticleView> {
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) var analyticsService
    
    private var article: Article!
    private var texts = [String]()
    private var buttonUrl: String?
    
    var articleDocument: Document?
    
    private let viewModel: ArticleVMProtocol
    
    // MARK: - Lifecycle
    
    init(viewModel: ArticleVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        makeNavigationTitle()
        configureMenu()
        configureView()
        
        viewModel.loadArticle()
        
        if viewModel.article.url.contains("to/20") {
//            viewModel.loadArticle(url: URL(string: viewModel.article.url)!)
        } else {
            makeDefaultArticle()
        }
    }
    
    private func makeNavigationTitle() {
        let label = MarqueeLabel(frame: .zero, rate: 30, fadeLength: 0)
        label.text = viewModel.article.title
        label.fadeLength = 30
        navigationItem.titleView = label
    }
    
    private func configureView() {
        NukeExtensions.loadImage(with: URL(string: viewModel.article.imageUrl)!, into: myView.articleImage)
        myView.titleLabel.text = viewModel.article.title
        myView.commentsLabel.text = R.string.localizable.comments(Int(viewModel.article.commentAmount) ?? 0)
    }
    
    // MARK: - Configure
    
    private func configureMenu() {
        let clipboardImage = UIImage(systemSymbol: .doc)
        let copyLinkItem = UIAction(title: R.string.localizable.copyLink(), image: clipboardImage) { [unowned self] _ in
            self.copyLinkTapped()
            analyticsService.copyArticleLink(viewModel.article.url)
        }
        
        let shareImage = UIImage(systemSymbol: .arrowTurnUpRight)
        let shareLinkItem = UIAction(title: R.string.localizable.shareLink(), image: shareImage) { [unowned self] _ in
            let items = [self.viewModel.article.url]
            let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
            self.present(activity, animated: true)
            analyticsService.shareArticleLink(viewModel.article.url)
        }
        
        let questionImage = UIImage(systemSymbol: .questionmarkCircle)
        let brokenArticleItem = UIAction(title: R.string.localizable.somethingWrongWithArticle(), image: questionImage) { [unowned self] _ in
            self.reportBrokenArticleTapped()
            analyticsService.reportBrokenArticle(viewModel.article.url)
        }
        
        let menu = UIMenu(title: "", options: .displayInline, children: [copyLinkItem, shareLinkItem, brokenArticleItem])
        
        if #available(iOS 14.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: nil, image: UIImage(systemSymbol: .ellipsis),
                                                                primaryAction: nil, menu: menu)
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemSymbol: .ellipsis), style: .plain,
                                                                target: self, action: #selector(copyLinkTapped))
        }
    }
    
    // MARK: - Actions
    
    @objc private func copyLinkTapped() {
        UIPasteboard.general.string = viewModel.article.url
        SwiftMessages.show {
            let view = MessageView.viewFromNib(layout: .centeredView)
            view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
            view.configureDropShadow()
            view.configureContent(title: R.string.localizable.copied(), body: "")
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            view.button?.isHidden = true
            return view
        }
    }
    
    @objc private func reportBrokenArticleTapped() {
        SwiftMessages.show {
            let view = MessageView.viewFromNib(layout: .centeredView)
            view.configureTheme(backgroundColor: .systemBlue, foregroundColor: .white)
            view.configureDropShadow()
            view.configureContent(title: R.string.localizable.thanks(), body: R.string.localizable.willFixSoon())
            (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
            view.button?.isHidden = true
            return view
        }
    }
    
    // MARK: - Functions
    
    func configureArticle(_ elements: [ArticleElement]) {
        myView.hideView.isHidden = true
        
        for element in elements {
            switch element {
            case let item as TextElement:
                addLabel(text: item.text,
                         isHeader: item.isHeader,
                         isQuote: item.isQuote,
                         inList: item.inList,
                         countedListIndex: item.countedListIndex)
            case let item as ImageElement:
                addImage(url: item.url, description: item.description)
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
    
    func configureComments(from page: String) {
        DispatchQueue.main.async {
            self.addComments(from: page)
        }
    }
    
    // MARK: - Privates
    
    private func makeDefaultArticle() {
        var description = viewModel.article.description
        if description.contains("Узнать подробнее") { description.removeLast(16) }
        configureArticle([TextElement(text: description),
                          ButtonElement(text: R.string.localizable.learnMore(),
                                        url: viewModel.article.url)])
        myView.removeComments()
    }
    
    private func addComments(from page: String) {
        let commentsVC = CommentsVC()
        commentsVC.article = viewModel.article
        commentsVC.articleDocument = page
        addChild(commentsVC)
        myView.commentsContainer.addSubview(commentsVC.view)
        myView.commentsContainer.isHidden = true
        commentsVC.view.snp.makeConstraints { make in
            make.top.bottom.leading.trailing.equalToSuperview()
        }
        commentsVC.didMove(toParent: self)
    }
    
    // MARK: - Labels
    
    private func addLabel(text: String, isHeader: Bool, isQuote: Bool, inList: Bool, countedListIndex: Int) {
        var newText = text
        if newText.contains("<!--more-->") { newText = newText.replacingOccurrences(of: "<!--more-->", with: "") }
        if newText.contains("<br>") { newText = newText.replacingOccurrences(of: "<br>", with: "") }
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
            $0.hyphenationFactor = 1
            $0.alignment = .justified
        }
        
        let style = StyleXML(base: baseStyle, [:])
        let attrText = newText.set(style: style)
        let textView = PDAResizingTextView()
        textView.myDelegate = self
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
            
            DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(stack) }
        } else if isHeader {
            let baseStyle = Style {
                $0.font = SystemFonts.HelveticaNeue_Medium.font(size: 20)
                $0.hyphenationFactor = 1
            }
            let style = StyleXML(base: baseStyle, [:])
            let attrText = newText.set(style: style)
            textView.attributedText = attrText
            textView.textColor = .label
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
    
    private func addImage(url: String, description: String?) {
        // todo make one view?
        if let description {
            let view = PDAResizingImageViewWithText(description)
            let imageOptions = ImageLoadingOptions(placeholder: UIImage(named: "placeholder"))
            NukeExtensions.loadImage(with: URL(string: url), options: imageOptions, into: view.imageView) { _ in }
            DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(view) }
        } else {
            let view = PDAResizingImageView()
            let imageOptions = ImageLoadingOptions(placeholder: UIImage(named: "placeholder"))
            NukeExtensions.loadImage(with: URL(string: url), options: imageOptions, into: view) { _ in }
            DispatchQueue.main.async { self.myView.stackView.addArrangedSubview(view) }
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
        let player = YouTubePlayerViewController(source: .video(id: id))
        player.view.snp.makeConstraints { make in
            make.height.equalTo(player.view.snp.width).multipliedBy(Double(9)/16)
        }
        DispatchQueue.main.async {
            self.myView.stackView.addArrangedSubview(player.view)
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
        button.addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        
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
    
    @objc private func buttonTapped() {
        if let buttonUrl, let url = URL(string: buttonUrl), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            analyticsService.clickButtonInArticle(currentUrl: viewModel.article.url, targetUrl: buttonUrl)
        }
    }
    
    private func unhide() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.myView.stopLoading()
            self.myView.commentsContainer.isHidden = false
        }
    }
}

// MARK: - ArticleVCProtocol

extension ArticleVC: ArticleVCProtocol {
    func configureArticle(with elements: [ArticleElement]) {
        DispatchQueue.main.async {
            self.configureArticle(elements)
        }
    }
    
    func showError() {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: R.string.localizable.error(),
                                          message: R.string.localizable.somethingWentWrong(),
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: R.string.localizable.ok(), style: .default))
            self.present(alert, animated: true)
        }
    }
}

// MARK: - PDAResizingTextViewDelegate

extension ArticleVC: PDAResizingTextViewDelegate {
    func willOpenURL(_ url: URL) {
        analyticsService.clickLinkInArticle(currentUrl: viewModel.article.url, targetUrl: url.absoluteString)
    }
}
