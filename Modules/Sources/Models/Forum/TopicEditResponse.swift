//
//  TopicEditResponse.swift
//  ForPDA
//
//  Created by Xialtal on 29.03.26.
//

public enum TopicEditResponse: Int, Sendable {
    case success = 0
    case tooManyQuestionsInPoll = 4
    case tooManyAnswersInPoll = 5
    case inappropriateContent = 6
    case sentToPremod = 7
    case noAccess
    
    public init(rawValue: Int) {
        switch rawValue {
        case 0: self = .success
        case 4: self = .tooManyQuestionsInPoll
        case 5: self = .tooManyAnswersInPoll
        case 6: self = .inappropriateContent
        case 7: self = .sentToPremod
        default: self = .noAccess
        }
    }
}
