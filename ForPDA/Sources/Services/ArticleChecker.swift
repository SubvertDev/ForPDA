//
//  ArticleChecker.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 05.11.2023.
//

import Foundation
import RouteComposer

final class ArticleChecker {
    
    static let isOn = false
    
    /// Opens and scrolls every loaded article if ``isOn`` set as true
    static func start(articles: [Article]) {
        Task { @MainActor in
            if #available(iOS 16.0, *) {
                try await Task.sleep(for: .seconds(3))
                // let articles = articles[0...]
                for (index, article) in articles.enumerated() {
                    print("[\(index)] Opening \(article.url)")
                    try DefaultRouter().navigate(to: RouteMap.articlePagesScreen, with: article)
                    try await Task.sleep(for: .seconds(1))
                    let controller = ClassFinder<ArticleVC, Any?>().getViewController()!
                    let item = controller.collectionView.numberOfItems(inSection: 0) - 1
                    let lastItemIndex = IndexPath(item: item, section: 0)
                    controller.collectionView.scrollToItem(at: lastItemIndex, at: .top, animated: true)
                    try await Task.sleep(for: .seconds(1.5))
                    try DefaultRouter().navigate(to: RouteMap.newsScreen, with: nil)
                    try await Task.sleep(for: .seconds(0.5))
                }
            }
        }
    }
    
}
