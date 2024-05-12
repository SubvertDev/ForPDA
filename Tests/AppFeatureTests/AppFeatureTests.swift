import XCTest
import ComposableArchitecture
import AppFeature
import NewsListFeature
import NewsFeature
import Models

final class AppFeatureTests: XCTestCase {
    
    @MainActor
    func testOpenNews() async {
        let news = NewsPreview.mock
        
        let store = TestStore(
            initialState: AppFeature.State(
                newsList: NewsListFeature.State(
                    news: [news]
                )
            )
        ) {
            AppFeature()
        }
        
        await store.send(\.newsList.newsTapped, news.id) {
            $0.path[id: 0] = .news(NewsFeature.State(news: news))
        }
    }
}
