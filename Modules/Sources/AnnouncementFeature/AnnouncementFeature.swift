//
//  AnnouncementFeature.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.24.
//

import Foundation
import ComposableArchitecture
import APIClient
import ParsingClient
import Models
import PersistenceKeys
import AnalyticsClient
import TopicBuilder
import ToastClient

@Reducer
public struct AnnouncementFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var announcementId: Int
        public var name: String?
        
        public var announcement: Announcement?
        
        var types: [[TopicTypeUI]] = []
        
        var didLoadOnce = false
       
        public init(id: Int, name: String? = nil) {
            self.announcementId = id
            self.name = name
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onAppear
        case urlTapped(URL)

        case _loadAnnouncement
        case _loadTypes([[TopicTypeUI]])
        case _announcementResponse(Result<Announcement, any Error>)
        
        case delegate(Delegate)
        public enum Delegate {
            case handleUrl(URL)
        }
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    @Dependency(\.toastClient) private var toastClient
    @Dependency(\.analyticsClient) private var analyticsClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onAppear:
                return .send(._loadAnnouncement)
                
            case ._loadAnnouncement:
                guard state.announcement == nil else { return .none }
                return .run { [id = state.announcementId] send in
                    let result = await Result { try await apiClient.getAnnouncement(id) }
                    await send(._announcementResponse(result))
                }
                
            case let .urlTapped(url):
                return .send(.delegate(.handleUrl(url)))
                   
            case let ._announcementResponse(.success(announcement)):
                // customDump(announcement)
                state.announcement = announcement
                state.name = state.name ?? announcement.name

                return .run { send in
                    var topicTypes: [[TopicTypeUI]] = []
                    
                    let types = TopicNodeBuilder(text: announcement.content, attachments: []).build()
                    topicTypes.append(types)
                    
                    await send(._loadTypes(topicTypes))
                }
                
            case let ._loadTypes(types):
                state.types = types
                reportFullyDisplayed(&state)
                return .none
                
            case ._announcementResponse(.failure):
                reportFullyDisplayed(&state)
                return .run { _ in await toastClient.showToast(.whoopsSomethingWentWrong) }
                
            case .delegate:
                return .none
            }
        }
        
        #warning("no analytics")
    }
    
    // MARK: - Shared Logic
    
    private func reportFullyDisplayed(_ state: inout State) {
        guard !state.didLoadOnce else { return }
        analyticsClient.reportFullyDisplayed()
        state.didLoadOnce = true
    }
}
