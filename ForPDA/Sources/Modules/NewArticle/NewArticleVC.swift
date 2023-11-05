//
//  NewArticleVC.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 04.11.2023.
//

import UIKit
import Factory
import MarqueeLabel
import RouteComposer
import SwiftMessages
import NukeExtensions

protocol NewArticleVCProtocol: AnyObject {
    func configureArticle(with elements: [ArticleElement])
    func reconfigureHeader(model: ArticleHeaderViewModel)
//    func makeComments(from page: String)
//    func updateComments(with document: String)
    func showError()
}

final class NewArticleVC: PDAViewController {
    
    // MARK: - Views
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.register(ArticleTextCell.self)
        collectionView.register(ArticleImageCell.self)
        collectionView.register(ArticleImageWithTextCell.self)
        collectionView.register(ArticleVideoCell.self)
        collectionView.register(ArticleGifCell.self)
        collectionView.register(ArticleButtonCell.self)
        collectionView.register(ArticleBulletListCell.self)
        collectionView.register(
            ArticleHeaderReusableView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: ArticleHeaderReusableView.reuseIdentifier
        )
        return collectionView
    }()
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) private var analytics
    @Injected(\.settingsService) private var settings
    
    let presenter: NewArticlePresenterProtocol
    lazy var dataSource = makeDataSource()
    
    //    private var commentsVC: CommentsVC?
    
    // MARK: - Init
    
    init(presenter: NewArticlePresenterProtocol) {
        self.presenter = presenter
        super.init()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        addSubviews()
        makeConstraints()
        
        configureNavigationTitle()
        configureMenu()
        configureView()
        
        collectionView.dataSource = dataSource
        update()
        
        // What is this check for? (todo)
        if presenter.article.url.contains("to/20") {
            Task {
                await presenter.loadArticle()
            }
        } else {
//            myView.removeComments()
//            let elements = ArticleBuilder.makeDefaultArticle(
//                description: presenter.article.info?.description ?? "Ошибка",
//                url: presenter.article.url
//            )
//            makeArticle(from: elements)
        }
    }
    
    // MARK: - Configuration
    
    private func configureNavigationTitle() {
        let label = MarqueeLabel(frame: .zero, rate: 30, fadeLength: 0)
        label.text = presenter.article.info?.title
        label.fadeLength = 30
        navigationItem.titleView = label
    }
    
    private func configureMenu() {
        let menu = UIMenu(title: "", options: .displayInline, children: [copyAction(), shareAction(), brokenAction()])
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemSymbol: .ellipsis), menu: menu)
    }
    
    private func configureView() {
//        myView.commentsLabel.text = R.string.localizable.comments(Int(presenter.article.info?.commentAmount ?? "0") ?? 0)
    }
    
    // MARK: - Menu Actions
    
    private func copyAction() -> UIAction {
        UIAction.make(title: R.string.localizable.copyLink(), symbol: .doc) { [unowned self] _ in
            UIPasteboard.general.string = presenter.article.url
            SwiftMessages.showDefault(title: R.string.localizable.copied(), body: "")
            analytics.event(Event.Article.articleLinkCopied.rawValue)
        }
    }
    
    private func shareAction() -> UIAction {
        UIAction.make(title: R.string.localizable.shareLink(), symbol: .arrowTurnUpRight) { [unowned self] _ in
            let activity = UIActivityViewController(activityItems: [presenter.article.url], applicationActivities: nil)
            present(activity, animated: true)
            analytics.event(Event.Article.articleLinkShared.rawValue)
        }
    }
    
    private func brokenAction() -> UIAction {
        UIAction.make(title: R.string.localizable.somethingWrongWithArticle(), symbol: .questionmarkCircle) { [unowned self] _ in
            analytics.event(Event.Article.articleLinkShared.rawValue)
            SwiftMessages.showDefault(title: R.string.localizable.thanks(), body: R.string.localizable.willFixSoon())
        }
    }
    
}

// MARK: - NewArticleVCProtocol

extension NewArticleVC: NewArticleVCProtocol {
    
    func configureArticle(with elements: [ArticleElement]) {
        Task { @MainActor in
            update(elements: elements)
        }
    }
    
    func reconfigureHeader(model: ArticleHeaderViewModel) {
        Task { @MainActor in
            let supplementary = collectionView.visibleSupplementaryViews(ofKind: UICollectionView.elementKindSectionHeader)
            if let articleHeader = supplementary.first as? ArticleHeaderReusableView {
                articleHeader.configure(model: model)
            }
            
            configureNavigationTitle()
        }
    }
    
    func showError() {
        // (todo) (important) vpn dies on this point FIX!
        let alert = UIAlertController(
            title: R.string.localizable.error(),
            message: R.string.localizable.somethingWentWrong(),
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: R.string.localizable.ok(), style: .default))
        present(alert, animated: true)
    }
    
}

// MARK: - Layout

extension NewArticleVC {
    
    private func addSubviews() {
        view.addSubview(collectionView)
    }
    
    private func makeConstraints() {
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
}
