import Foundation
import Testing
import Models
import ComposableArchitecture

@testable import AppFeature

import ArticleFeature
import SettingsFeature

@MainActor
@Suite("App Tests")
struct AppFeatureTest {
    
    init() { uncheckedUseMainSerialExecutor = true }
    
    @Test("Open article")
    func openArticle() async throws {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        
        let preview: ArticlePreview = .mock
        
        await store.send(.articlesList(.articleTapped(preview))) {
            $0.isShowingTabBar = false
            $0.articlesPath[id: 0] = .article(ArticleFeature.State(articlePreview: preview))
        }
    }
    
    @Test("Open settings")
    func openSettings() async throws {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }
        
        await store.send(.articlesList(.settingsButtonTapped)) {
            $0.isShowingTabBar = false
            $0.articlesPath[id: 0] = .settingsPath(.settings(SettingsFeature.State()))
        }
    }
}
