import Foundation

public struct NewsPreview: Identifiable, Equatable {
    
    public let url: URL
    public let title: String
    public let description: String
    public let imageUrl: URL
    public let author: String
    public let date: String
    public let isReview: Bool
    public let commentAmount: String
    
    public var id: String { url.absoluteString }
    
    public var path: [String] {
        return url.pathComponents // RELEASE: What do I need this for?
    }
    
    public init(
        url: URL,
        title: String,
        description: String,
        imageUrl: URL,
        author: String,
        date: String,
        isReview: Bool,
        commentAmount: String
    ) {
        self.url = url
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.author = author
        self.date = date
        self.isReview = isReview
        self.commentAmount = commentAmount
    }
    
    public static func == (lhs: NewsPreview, rhs: NewsPreview) -> Bool {
        return lhs.url == rhs.url
    }
}

public extension NewsPreview {
    
    // RELEASE: Remove random in URL
    static let mock = NewsPreview(
        url: URL(string: "https://4pda.to/2024/03/20/425729/bogoborchestvo_gejmery_vybrali_glavnyj_khit_playstation/\(String(Int.random(in: 0...1000)))")!,
        title: "Богоборчество. Геймеры выбрали главный хит PlayStation",
        description: "Геймеры любят две вещи — материалы-подборки и опросы на тему любимых игр. Журналисты и издатели нагло этим пользуются: на прошлой неделе Sony, например, решила выяснить, какой из недавних эксклюзивов PlayStation публика любит больше всего. Что ж, народ сделал свой выбор.",
        imageUrl: URL(string: "https://4pda.to/s/Zy0hIejPviN8gsdKRo1w1tcRxouUXo5P22iXG1Univz0K.jpg?v=1710934951")!,
        author: "Валентин Карузов",
        date: "20.03.24",
        isReview: false,
        commentAmount: "19"
    )
}
