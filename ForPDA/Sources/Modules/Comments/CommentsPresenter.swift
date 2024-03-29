//
//  CommentsPresenter.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 19.11.2023.
//

import Factory

protocol CommentsPresenterProtocol {
    var themeColor: AppNightModeBackgroundColor { get }
    
    func updateComments() async
    func commentsHasUpdated()
    func refreshControlCalled()
}

final class CommentsPresenter: CommentsPresenterProtocol {
    
    // MARK: - Properties
    
    @LazyInjected(\.newsService) private var news
    @LazyInjected(\.parsingService) private var parser
    @Injected(\.settingsService) private var settings
    
    weak var view: (CommentsVCProtocol & Alertable)?
    
    private let article: Article
    
    var themeColor: AppNightModeBackgroundColor {
        settings.getAppBackgroundColor()
    }
    var hasShownCommentsOnce = false
    
    // MARK: - Init
    
    init(article: Article) {
        self.article = article
    }
    
    // MARK: - Public Functions
    
    func updateComments() async {
        do {
            let response = try await news.comments(path: article.path)
            let comments = parser.parseComments(from: response)
            view?.updateComments(with: comments)
        } catch {
            view?.showAlert(title: R.string.localizable.error(), message: error.localizedDescription)
        }
    }
    
    // Case when we have Show Likes option and we need to reload
    // comments with likes after FLS comments are loaded
    func commentsHasUpdated() {
        Task {
            if !hasShownCommentsOnce && settings.getFastLoadingSystem() {
                await updateComments()
                hasShownCommentsOnce = true
            } else if !hasShownCommentsOnce {
                hasShownCommentsOnce = true
            }
        }
    }
    
    func refreshControlCalled() {
        guard hasShownCommentsOnce else { return }
        Task {
            await updateComments()
        }
    }
}
