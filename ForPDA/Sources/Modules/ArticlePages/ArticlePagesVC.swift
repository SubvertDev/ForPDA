//
//  ArticlePagesVC.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 16.11.2023.
//

import UIKit
import SnapKit
import Factory
import MarqueeLabel
import SwiftMessages
import Sentry

protocol ArticlePagesVCProtocol: AnyObject {
    func configureArticle(elements: [ArticleElement], comments: [Comment])
    func reconfigureHeader(model: ArticleHeaderViewModel)
}

final class ArticlePagesVC: PDAViewController {
    
    // MARK: - Views
    
    private lazy var headerView: ArticleHeaderView = {
        let model = ArticleHeaderViewModel(
            imageUrl: presenter.article.info?.imageUrl,
            title: presenter.article.info?.title
        )
        let header = ArticleHeaderView()
        header.configure(model: model)
        header.clipsToBounds = true
        return header
    }()
    
    private lazy var pageVC: UIPageViewController = {
        let page = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        page.delegate = self
        page.dataSource = self
        self.addChild(page)
        page.didMove(toParent: self)
        page.setViewControllers([viewControllers[0]], direction: .forward, animated: false)
        let scrollView = page.view.subviews.compactMap({ $0 as? UIScrollView }).first!
        scrollView.delegate = self
        return page
    }()
    
    // MARK: - Properties
    
    @LazyInjected(\.analyticsService) private var analytics
    
    private let presenter: ArticlePagesPresenterProtocol
    
    private lazy var viewControllers = [
        try! ArticleFactory().build(with: presenter.article),
        try! CommentsFactory().build(with: presenter.article)
    ]
    
    private var newArticleVC: ArticleVCProtocol {
        return viewControllers[0] as! ArticleVC
    }
    
    private var commentsVC: CommentsVCProtocol {
        return viewControllers[1] as! CommentsVC
    }
    
    // MARK: Scroll Properties
    
    private var currentIndex = 0
    private var dragInitialY: CGFloat = 0
    private var dragPreviousY: CGFloat = 0
    private var dragDirection: DragDirection = .up
    
    private var headerViewHeightConstraint: Constraint!
    private var headerHeight: CGFloat {
        get { headerViewHeightConstraint.layoutConstraints[0].constant }
        set { headerViewHeightConstraint.layoutConstraints[0].constant = newValue }
    }
    
    private let topViewInitialHeight: CGFloat = UIScreen.main.bounds.width * 0.6
    private let topViewFinalHeight: CGFloat = 0
    var topViewHeightConstraintRange: Range<CGFloat> {
        return topViewFinalHeight ..< topViewInitialHeight
    }
    
    // MARK: - Init
    
    init(presenter: ArticlePagesPresenterProtocol) {
        self.presenter = presenter
        super.init()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addSubviews()
        makeConstraints()
                
        configureNavigationTitle()
        configureMenu()
        configureHeader()
        configureDelegates()
        
        Task {
            await presenter.loadArticle()
        }
    }
}

// MARK: - ArticlePagesVCProtocol

extension ArticlePagesVC: ArticlePagesVCProtocol {
    
    func configureArticle(elements: [ArticleElement], comments: [Comment]) {
        newArticleVC.configureArticle(with: elements)
        commentsVC.updateComments(with: comments)
    }
    
    func reconfigureHeader(model: ArticleHeaderViewModel) {
        headerView.configure(model: model)
        configureNavigationTitle(model.title)
    }
}

// MARK: - Scrolling & Header

extension ArticlePagesVC: ArticleInnerScrollViewDelegate {
    
    var currentHeaderHeight: CGFloat {
        return headerHeight
    }
    
    @objc func topViewMoved(_ gesture: UIPanGestureRecognizer) {
        var dragYDiff: CGFloat
        
        switch gesture.state {
        case .began:
            dragInitialY = gesture.location(in: view).y
            dragPreviousY = dragInitialY
            
        case .changed:
            let dragCurrentY = gesture.location(in: view).y
            dragYDiff = dragPreviousY - dragCurrentY
            dragPreviousY = dragCurrentY
            dragDirection = dragYDiff < 0 ? .down : .up
            innerCollectionViewDidScroll(withDistance: dragYDiff)
            
        case .ended:
            innerCollectionViewScrollEnded(withScrollDirection: dragDirection)
            
        default: 
            return
        }
    }
    
    func innerCollectionViewDidScroll(withDistance scrollDistance: CGFloat) {
        headerHeight -= scrollDistance
        
        // Restricts the downward scroll.
        if headerHeight > topViewInitialHeight {
            headerHeight = topViewInitialHeight
        }
        
        if headerHeight < topViewFinalHeight {
            headerHeight = topViewFinalHeight
        }
    }
    
    func innerCollectionViewScrollEnded(withScrollDirection scrollDirection: DragDirection) {
        // *  Scroll is not restricted.
        // *  So this check might cause the view to get stuck in the header height is greater than initial height.
        // if topViewHeight >= topViewInitialHeight || topViewHeight <= topViewFinalHeight { return }
        
        if headerHeight <= topViewFinalHeight + 20 {
            scrollToFinalView()
        } else if headerHeight <= topViewInitialHeight - 20 {
            switch scrollDirection {
            case .down: scrollToInitialView()
            case .up: scrollToFinalView()
            }
        } else {
            scrollToInitialView()
        }
    }
    
    private func scrollToInitialView() {
        let topViewCurrentHeight = headerView.frame.height
        let distanceToBeMoved = abs(topViewCurrentHeight - topViewInitialHeight)
        var time = distanceToBeMoved / 500
        if time < 0.25 {
            time = 0.25
        }
        headerHeight = topViewInitialHeight
        UIView.animate(withDuration: TimeInterval(time)) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func scrollToFinalView() {
        let topViewCurrentHeight = headerView.frame.height
        let distanceToBeMoved = abs(topViewCurrentHeight - topViewFinalHeight)
        var time = distanceToBeMoved / 500
        if time < 0.25 {
            time = 0.25
        }
        headerHeight = topViewFinalHeight
        UIView.animate(withDuration: TimeInterval(time)) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - ScrollView Delegate (for pager)

extension ArticlePagesVC: UIScrollViewDelegate {
    
    func scrollViewDidScroll(
        _ scrollView: UIScrollView
    ) {
        if (currentIndex == 0 && scrollView.contentOffset.x < scrollView.bounds.size.width)
            ||
            (currentIndex == viewControllers.count - 1 && scrollView.contentOffset.x > scrollView.bounds.size.width)
            ||
            !presenter.isLoaded
        {
            scrollView.contentOffset = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }
    
    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        if (currentIndex == 0 && scrollView.contentOffset.x <= scrollView.bounds.size.width)
            ||
            (currentIndex == viewControllers.count - 1 && scrollView.contentOffset.x >= scrollView.bounds.size.width)
        {
            targetContentOffset.pointee = CGPoint(x: scrollView.bounds.size.width, y: 0)
        }
    }
}

// MARK: - Page Delegate & DataSource

extension ArticlePagesVC: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerBefore viewController: UIViewController
    ) -> UIViewController? {
        guard viewController is CommentsVC else { return nil }
        return viewControllers[0]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        viewControllerAfter viewController: UIViewController
    ) -> UIViewController? {
        guard viewController is ArticleVC else { return nil }
        return viewControllers[1]
    }
    
    func pageViewController(
        _ pageViewController: UIPageViewController,
        didFinishAnimating finished: Bool,
        previousViewControllers: [UIViewController],
        transitionCompleted completed: Bool
    ) {
        guard completed else { return }
        guard let newIndex = viewControllers.firstIndex(where: { $0 == pageVC.viewControllers?.first }) else { return }
        currentIndex = newIndex
        if currentIndex == 0 {
            analytics.event(Event.Article.articleCommentsClosed.rawValue)
        } else {
            analytics.event(Event.Article.articleCommentsOpened.rawValue)
        }
    }
}

// MARK: - ArticlePageControllerDelegate

extension ArticlePagesVC: ArticlePageControllerDelegate {
    
    func footerTapped() {
        view.isUserInteractionEnabled = false
        pageVC.setViewControllers(
            [viewControllers[1]],
            direction: .forward,
            animated: true
        ) { [weak self] _ in
            guard let self else { return }
            view.isUserInteractionEnabled = true
            currentIndex = 1
        }
    }
}

// MARK: - NavBar Configuration

extension ArticlePagesVC {
    
    private func configureNavigationTitle(_ deeplinkTitle: String? = nil) {
        let label = MarqueeLabel(frame: .zero, rate: 30, fadeLength: 0)
        label.text = deeplinkTitle != nil ? deeplinkTitle : presenter.article.info?.title
        label.fadeLength = 30
        navigationItem.titleView = label
    }
    
    private func configureMenu() {
        let menu = UIMenu(title: "", options: .displayInline, children: [copyAction(), shareAction(), reportAction()])
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemSymbol: .ellipsis), menu: menu)
    }
    
    private func copyAction() -> UIAction {
        UIAction.make(title: R.string.localizable.copyLink(), symbol: .doc) { [unowned self] _ in
            analytics.event(Event.Article.articleLinkCopied.rawValue)
            UIPasteboard.general.string = presenter.article.url
            SwiftMessages.showDefault(title: R.string.localizable.copied(), body: "")
        }
    }
    
    private func shareAction() -> UIAction {
        UIAction.make(title: R.string.localizable.shareLink(), symbol: .arrowTurnUpRight) { [unowned self] _ in
            analytics.event(Event.Article.articleLinkShared.rawValue)
            let activity = UIActivityViewController(activityItems: [presenter.article.url], applicationActivities: nil)
            present(activity, animated: true)
        }
    }
    
    private func reportAction() -> UIAction {
        UIAction.make(title: R.string.localizable.somethingWrongWithArticle(), symbol: .questionmarkCircle) { [unowned self] _ in
            analytics.event(Event.Article.articleReport.rawValue)
            SentrySDK.capture(error: SentryCustomError.badArticle(url: presenter.article.url))
            SwiftMessages.showDefault(title: R.string.localizable.thanks(), body: R.string.localizable.willFixSoon())
        }
    }
    
    private func configureHeader() {
        let topViewPanGesture = UIPanGestureRecognizer(target: self, action: #selector(topViewMoved))
        headerView.isUserInteractionEnabled = true
        headerView.addGestureRecognizer(topViewPanGesture)
    }
    
    private func configureDelegates() {
        if let newArticleVC = viewControllers[0] as? ArticleVC {
            newArticleVC.collectionViewScrollDelegate = self
            newArticleVC.pageControllerDelegate = self
        }
        
        if let commentsVC = viewControllers[1] as? CommentsVC {
            commentsVC.collectionViewScrollDelegate = self
            // For some reason CommentsVC doesn't load without this line, investigate (todo)
            commentsVC.view.backgroundColor = .systemBackground
        }
    }
}

// MARK: - Layout

extension ArticlePagesVC {
    
    private func addSubviews() {
        view.addSubview(headerView)
        view.addSubview(pageVC.view)
    }
    
    private func makeConstraints() {
        headerView.snp.makeConstraints { make in
            headerViewHeightConstraint = make.height.equalTo(topViewInitialHeight).constraint
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.horizontalEdges.equalToSuperview()
        }
        
        pageVC.view.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
}
