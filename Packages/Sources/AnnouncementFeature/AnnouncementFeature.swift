//
//  AnnouncementFeature.swift
//  ForPDA
//
//  Created by Xialtal on 24.11.24.
//

import Foundation
import ComposableArchitecture
import APIClient
import TopicFeature
import ParsingClient
import Models
import PersistenceKeys

@Reducer
public struct AnnouncementFeature: Reducer, Sendable {
    
    public init() {}
    
    // MARK: - State
    
    @ObservableState
    public struct State: Equatable {
        public var id: Int
        public var name: String
        
        public var announcement: Announcement?
        
        var types: [[TopicTypeUI]] = []
       
        public init(id: Int, name: String) {
            self.id = id
            self.name = name
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped

        case _loadAnnouncement
        case _loadTypes([[TopicTypeUI]])
        case _announcementResponse(Result<Announcement, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .send(._loadAnnouncement)
                
            case ._loadAnnouncement:
                guard state.announcement == nil else { return .none }
                return .run { [id = state.id] send in
                    let result = await Result { try await apiClient.getAnnouncement(id: id) }
                    await send(._announcementResponse(result))
                }
                
            case .settingsButtonTapped:
                return .none
                   
            case let ._announcementResponse(.success(announcement)):
                // customDump(announcement)
                state.announcement = announcement

                return .run { send in
                    var topicTypes: [[TopicTypeUI]] = []
                    
                    let parsedContent = BBCodeParser.parse(announcement.content)!
                    let types = try! TopicBuilder().build(from: parsedContent)
                    topicTypes.append(types)
                    
                    await send(._loadTypes(topicTypes))
                }
                
            case let ._loadTypes(types):
                state.types = types
                return .none
                
            case let ._announcementResponse(.failure(error)):
                // TODO: Handle error
                print(error)
                return .none
            }
        }
    }
}
