import XCTest
import ComposableArchitecture
import AppFeature
import ArticlesListFeature
import NewsFeature
import Models

final class AppFeatureTests: XCTestCase {
    
    @MainActor
    func testOpenNews() async {
        let news = NewsPreview.mock
        
        let store = TestStore(
            initialState: AppFeature.State(
                articlesList: ArticlesListFeature.State(
                    articles: []
                )
            )
        ) {
            AppFeature()
        }
        
        await store.send(\.articlesList.articleTapped, article.id) {
            $0.path[id: 0] = .news(NewsFeature.State(news: news))
        }
    }
}
