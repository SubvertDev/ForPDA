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
}

final class NewArticleVC: PDAViewController {
    
    // MARK: - Views
    
    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        collectionView.delegate = self
        
        collectionView.register(ArticleTextCell.self)
        collectionView.register(ArticleImageCell.self)
        collectionView.register(ArticleImageWithTextCell.self)
        collectionView.register(ArticleVideoCell.self)
        collectionView.register(ArticleGifCell.self)
        collectionView.register(ArticleButtonCell.self)
        collectionView.register(ArticleBulletListCell.self)
        collectionView.registerFooter(ArticleCommentsFooterView.self)
                
        return collectionView
    }()
    
    // MARK: - Properties
    
    @Injected(\.analyticsService) private var analytics
    @Injected(\.settingsService) private var settings
    
    let presenter: NewArticlePresenterProtocol
    lazy var dataSource = makeDataSource()
    
    weak var pageControllerDelegate: ArticlePageControllerDelegate?
    weak var collectionViewScrollDelegate: ArticleInnerScrollViewDelegate?
    var dragDirection: DragDirection = .up
    var oldContentOffset: CGPoint = .zero
    
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
        
        collectionView.dataSource = dataSource
    }
}

// MARK: - ArticleCommentsReusableViewDelegate

extension NewArticleVC: ArticleCommentsFooterViewDelegate {
    
    func footerTapped() {
        pageControllerDelegate?.footerTapped()
    }
}

// MARK: - NewArticleVCProtocol

extension NewArticleVC: NewArticleVCProtocol {

    func configureArticle(with elements: [ArticleElement]) {
        Task { @MainActor in
            update(elements: elements)
        }
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
