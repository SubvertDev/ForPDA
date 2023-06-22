//
//  ArticleVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import Factory
import MarqueeLabel
import SwiftMessages
import SFSafeSymbols
import NukeExtensions

protocol ArticleVCProtocol: AnyObject {
    func configureArticle(with elements: [ArticleElement])
    func makeComments(from page: String)
    func showError()
}

final class ArticleVC: PDAViewController<ArticleView> {
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) private var analyticsService
    @Injected(\.settingsService) private var settingsService
    
    private let viewModel: ArticleVMProtocol
    private var commentsVC: CommentsVC?
    
    // MARK: - Lifecycle
    
    init(viewModel: ArticleVMProtocol) {
        self.viewModel = viewModel
        super.init()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        configureNavigationTitle()
        configureMenu()
        configureView()
        myView.delegate = self
        
        viewModel.loadArticle()
        
        if viewModel.article.url.contains("to/20") { // ---- ????
//            viewModel.loadArticle(url: URL(string: viewModel.article.url)!)
        } else {
            myView.removeComments()
            let elements = ArticleBuilder.makeDefaultArticle(description: viewModel.article.description, url: viewModel.article.url)
            makeArticle(from: elements)
        }
    }
    
    // MARK: - Configuration
    
    private func configureNavigationTitle() {
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
    
    private func configureMenu() {
        let menu = UIMenu(title: "", options: .displayInline, children: [copyAction(), shareAction(), brokenAction()])
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemSymbol: .ellipsis), menu: menu)
    }
    
    // MARK: - Actions
    
    private func copyAction() -> UIAction {
        UIAction.make(title: R.string.localizable.copyLink(), symbol: .doc) { [unowned self] _ in
            UIPasteboard.general.string = viewModel.article.url
            analyticsService.copyArticleLink(viewModel.article.url)
            SwiftMessages.showDefault(title: R.string.localizable.copied(), body: "")
        }
    }
    
    private func shareAction() -> UIAction {
        UIAction.make(title: R.string.localizable.shareLink(), symbol: .arrowTurnUpRight) { [unowned self] _ in
            let activity = UIActivityViewController(activityItems: [viewModel.article.url], applicationActivities: nil)
            analyticsService.shareArticleLink(viewModel.article.url)
            present(activity, animated: true)
        }
    }
    
    private func brokenAction() -> UIAction {
        UIAction.make(title: R.string.localizable.somethingWrongWithArticle(), symbol: .questionmarkCircle) { [unowned self] _ in
            analyticsService.reportBrokenArticle(viewModel.article.url)
            SwiftMessages.showDefault(title: R.string.localizable.thanks(), body: R.string.localizable.willFixSoon())
        }
    }
    
    private func externalLinkButtonTapped(_ link: String) {
        if let url = URL(string: link), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            analyticsService.clickButtonInArticle(currentUrl: viewModel.article.url, targetUrl: url.absoluteString)
        }
    }
    
    // MARK: - Making Article
    
    func makeArticle(from elements: [ArticleElement]) {
        for element in elements {
            var articleElement: UIView?
            switch element {
            case let item as TextElement:
                articleElement = ArticleBuilder.addLabel(
                    text: item.text,
                    isHeader: item.isHeader,
                    isQuote: item.isQuote,
                    inList: item.inList,
                    countedListIndex: item.countedListIndex,
                    delegate: self
                )
                
            case let item as ImageElement:
                articleElement = ArticleBuilder.addImage(url: item.url, description: item.description)
                
            case let item as VideoElement:
                articleElement = ArticleBuilder.addVideo(id: item.url)
                
            case let item as GifElement:
                articleElement = ArticleBuilder.addGif(url: item.url)
                
            case let item as ButtonElement:
                articleElement = ArticleBuilder.addButton(text: item.text, url: item.url) { [weak self] link in
                    self?.externalLinkButtonTapped(link)
                }
                
            case let item as BulletListParentElement:
                articleElement = ArticleBuilder.addBulletList(bulletList: item.elements)
                
            default:
                break
            }
            
            guard let articleElement else { continue }
            myView.stackView.addArrangedSubview(articleElement)
        }
        
        myView.commentsContainer.isHidden = false
        myView.stopLoading()
    }
    
    // MARK: - Making Comments
    
    func makeComments(from page: String) {
        commentsVC = CommentsVC(article: viewModel.article, document: page)
        guard let commentsVC else { return }
        commentsVC.updateDelegate = self
        addChild(commentsVC)
        myView.commentsContainer.addSubview(commentsVC.view)
        myView.commentsContainer.isHidden = true
        commentsVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        commentsVC.didMove(toParent: self)
    }
}

// MARK: - ArticleVCProtocol

extension ArticleVC: ArticleVCProtocol {
    
    func configureArticle(with elements: [ArticleElement]) {
        DispatchQueue.main.async {
            self.makeArticle(from: elements)
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

// MARK: - ArticleViewDelegate

extension ArticleVC: ArticleViewDelegate {
    func updateCommentsButtonTapped() {
        commentsVC?.updateAll()
    }
}

// MARK: - CommentsVCProtocol

extension ArticleVC: CommentsVCProtocol {
    func updateStarted() {
        let image = UIImage(
            systemSymbol: .arrowTriangle2Circlepath,
            withConfiguration: UIImage.SymbolConfiguration(weight: .bold)
        )
        myView.updateCommentsButton.rotate360Degrees(duration: 1, repeatCount: .infinity)
    }
    
    func updateFinished(_ state: Bool) {
        let image = UIImage(
            systemSymbol: state ? .arrowTriangle2Circlepath : .exclamationmarkArrowTriangle2Circlepath,
            withConfiguration: UIImage.SymbolConfiguration(weight: .bold)
        )
        myView.updateCommentsButton.setImage(image, for: .normal)
        myView.updateCommentsButton.stopButtonRotation()
    }
}

// MARK: - PDAResizingTextViewDelegate

extension ArticleVC: PDAResizingTextViewDelegate {
    func willOpenURL(_ url: URL) {
        analyticsService.clickLinkInArticle(currentUrl: viewModel.article.url, targetUrl: url.absoluteString)
    }
}
