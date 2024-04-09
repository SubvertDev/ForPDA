//
//  News.swift
//  ForPDA
//
//  Created by Ilia Lubianoi on 21.03.2024.
//

import Foundation

struct News: Identifiable {
    let url: URL
    let info: NewsInfo
    
    var id: String { url.absoluteString + String(Int.random(in: 0...1000)) }
}

struct NewsInfo {
    let title: String
    let description: String
    let imageUrl: URL
    let author: String
    let date: String
    let isReview: Bool
    let commentAmount: String
}

extension News {
    static let mock = News(
        url: URL(string: "https://4pda.to/2024/03/20/425729/bogoborchestvo_gejmery_vybrali_glavnyj_khit_playstation/")!,
        info: NewsInfo(
            title: "Богоборчество. Геймеры выбрали главный хит PlayStation",
            description: "Геймеры любят две вещи — материалы-подборки и опросы на тему любимых игр. Журналисты и издатели нагло этим пользуются: на прошлой неделе Sony, например, решила выяснить, какой из недавних эксклюзивов PlayStation публика любит больше всего. Что ж, народ сделал свой выбор.",
            imageUrl: URL(string: "https://4pda.to/s/Zy0hIejPviN8gsdKRo1w1tcRxouUXo5P22iXG1Univz0K.jpg?v=1710934951")!,
            author: "Валентин Карузов",
            date: "20.03.24",
            isReview: false,
            commentAmount: "19"
        )
    )
}
