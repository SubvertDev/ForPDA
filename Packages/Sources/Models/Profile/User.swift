//
//  User.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 02.08.2024.
//

import Foundation

public struct User: Sendable, Hashable, Codable {
    public let id: Int
    public let nickname: String
    public let imageUrl: URL
    public let group: Group
    public let status: String?
    public let signature: String?
    public let aboutMe: String?
    public let registrationDate: Date
    public let lastSeenDate: Date
    public let birthdate: String?
    public let gender: Gender?
    public let userTime: Int?
    public let city: String?
    public let devDBdevices: [Device]?
    public let karma: Int
    public let posts: Int
    public let comments: Int
    public let reputation: Int
    public let topics: Int
    public let replies: Int
    public let qmsMessages: Int?
    public let forumDevices: [Device]?
    public let email: String?
    
    public var userTimeFormatted: String? {
        if let userTime {
            let currentDate = Date()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            // let gmtTimeString = dateFormatter.string(from: currentDate)
            let gmtDateWithOffset = currentDate.addingTimeInterval(TimeInterval(userTime))
            let offsetTimeString = dateFormatter.string(from: gmtDateWithOffset)
            return offsetTimeString
        } else {
            return nil
        }
    }
    
    public init(
        id: Int,
        nickname: String,
        imageUrl: URL?,
        group: Group,
        status: String?,
        signature: String?,
        aboutMe: String?,
        registrationDate: Date,
        lastSeenDate: Date,
        birthdate: String?,
        gender: Gender?,
        userTime: Int?,
        city: String?,
        devDBdevices: [Device]?,
        karma: Int,
        posts: Int,
        comments: Int,
        reputation: Int,
        topics: Int,
        replies: Int,
        qmsMessages: Int?,
        forumDevices: [Device]?,
        email: String?
    ) {
        self.id = id
        self.nickname = nickname
        self.imageUrl = imageUrl ?? Links.defaultAvatar
        self.group = group
        self.status = status
        self.signature = signature
        self.aboutMe = aboutMe
        self.registrationDate = registrationDate
        self.lastSeenDate = lastSeenDate
        self.birthdate = birthdate
        self.gender = gender
        self.userTime = userTime
        self.city = city
        self.devDBdevices = devDBdevices
        self.karma = karma
        self.posts = posts
        self.comments = comments
        self.reputation = reputation
        self.topics = topics
        self.replies = replies
        self.qmsMessages = qmsMessages
        self.forumDevices = forumDevices
        self.email = email
    }
}

// MARK: - Type Extension

public extension User {
    
    // MARK: Group
    
    enum Group: Int, Codable, Hashable, Sendable {
        /// User registered, but account
        /// not activated.
        case nonActivated = 1
        case guest = 2
        /// Base user group after registration
        /// and activating account.
        case beginning = 3
        case admin = 4
        case banned = 5
        /// `beginning`, but has 15 messages in forum,
        /// also get more forum features.
        case active = 7
        /// Old naming - Friends 4PDA. User. that
        /// has 50 messages in forum.
        case regular = 8
        case moderator = 9
        case supermoderator = 10
        case moderatorHelper = 11
        case faqMaker = 12
        case honorary = 13
        case developer = 15
        case router = 16
        case buisnessman = 17
        /// Member of internal spec-projects.
        case specproject = 18
        case moderatorSchool = 19
        case curator = 20

        
        public var title: String {
            switch self {
            case .nonActivated:
                return "Не активирован"
            case .guest:
                return "Гость"
            case .beginning:
                return "Начинающий"
            case .admin:
                return "Администратор"
            case .banned:
                return "Забанен"
            case .active:
                return "Активный"
            case .regular:
                return "Постоянный"
            case .moderator:
                return "Модератор"
            case .supermoderator:
                return "Супермодератор"
            case .moderatorHelper:
                return "Помощник модератора"
            case .faqMaker:
                return "FAQMaker"
            case .honorary:
                return "Почётный форумчанин"
            case .developer:
                return "Разработчик"
            case .router:
                return "Роутер"
            case .buisnessman:
                return "Бизнесмен"
            case .specproject:
                return "Спецпроекты"
            case .moderatorSchool:
                return "Школа модераторов"
            case .curator:
                return "Куратор"
            }
        }
    }
    
    // MARK: Gender
    
    enum Gender: Int, Codable, Hashable, Sendable {
        case unknown = 0
        case male
        case female
        
        public var title: String {
            switch self {
            case .unknown:
                "Неизвестно"
            case .male:
                "Мужчина"
            case .female:
                "Женщина"
            }
        }
    }
    
    // MARK: Device
    
    struct Device: Codable, Hashable, Sendable {
        let name: String
    }
}

// MARK: - Mock

public extension User {
    static let mock = User(
        id: 0,
        nickname: "Test Nickname",
        imageUrl: Links.defaultAvatar,
        group: .active,
        status: "Very strange status text indeed",
        signature: "Developer",
        aboutMe: "A lot of text about me. A lot of text about me. A lot of text about me. A lot of text about me. A lot of text about me.",
        registrationDate: Date(timeIntervalSince1970: 1168875045),
        lastSeenDate: Date(timeIntervalSince1970: 1200000000),
        birthdate: "01.01.2000",
        gender: .male,
        userTime: 10800,
        city: "Moscow",
        devDBdevices: nil,
        karma: 1500,
        posts: 23,
        comments: 173,
        reputation: 78,
        topics: 5,
        replies: 82,
        qmsMessages: nil,
        forumDevices: nil,
        email: "some@email.com"
    )
}
