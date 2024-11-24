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
        @Shared(.appSettings) var appSettings: AppSettings

        public var announcementId: Int
        public var announcementName: String
        
        public var announcement: Announcement?
        
        var types: [[TopicType]] = []

        public var isLoading = false
        
        public init(
            announcementId: Int,
            announcementName: String
        ) {
            self.announcementId = announcementId
            self.announcementName = announcementName
        }
    }
    
    // MARK: - Action
    
    public enum Action {
        case onTask
        case settingsButtonTapped

        case _loadAnnouncement
        case _loadTypes([[TopicType]])
        case _announcementResponse(Result<Announcement, any Error>)
    }
    
    // MARK: - Dependencies
    
    @Dependency(\.apiClient) private var apiClient
    
    // MARK: - Cancellable
    
    private enum CancelID { case loading }
    
    // MARK: - Body
    
    public var body: some Reducer<State, Action> {
        Reduce<State, Action> { state, action in
            switch action {
            case .onTask:
                return .send(._loadAnnouncement)
                
            case ._loadAnnouncement:
                state.isLoading = true
                return .run { [id = state.announcementId] send in
                    let result = await Result { try await apiClient.getAnnouncement(id: id) }
                    await send(._announcementResponse(result))
                }
                
            case .settingsButtonTapped:
                return .none
                   
            case let ._announcementResponse(.success(announcement)):
                state.announcement = announcement

                return .run { send in
                    var topicTypes: [[TopicType]] = []
                    
                    let parsedContent = BBCodeParser.parse(announcement.content)!
                    let types = try! TopicBuilder.build(from: parsedContent)
                    topicTypes.append(types)
                    
                    await send(._loadTypes(topicTypes))
                }
                .cancellable(id: CancelID.loading)
                
            case let ._loadTypes(types):
                state.types = types
                state.isLoading = false
                return .none
                
            case let ._announcementResponse(.failure(error)):
                // TODO: Handle error
                print(error)
                return .none
            }
        }
    }
}
