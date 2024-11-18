//
//  Post.swift
//  ForPDA
//
//  Created by Xialtal on 7.09.24.
//

import Foundation

public struct Post: Sendable, Hashable, Identifiable, Codable {
    public let id: Int
    public let first: Bool
    public let content: String
    public let author: Author
    public let karma: Int
    public let attachments: [Attachment]
    public let createdAt: Date
    public let lastEdit: LastEdit?
    
    // TODO: 12 => 0 on first post; other - 1; can be 17 also
    
    public init(
        id: Int,
        first: Bool,
        content: String,
        author: Author,
        karma: Int,
        attachments: [Attachment],
        createdAt: Date,
        lastEdit: LastEdit?
    ) {
        self.id = id
        self.first = first
        self.content = content
        self.author = author
        self.karma = karma
        self.attachments = attachments
        self.createdAt = createdAt
        self.lastEdit = lastEdit
    }
    
    public struct Attachment: Sendable, Hashable, Codable {
        public let id: Int
        public let type: AttachmentType
        public let name: String
        public let size: Int
        public let metadata: Metadata?
        
        public enum AttachmentType: Sendable, Hashable, Codable {
            case file
            case image
        }
        
        public struct Metadata: Sendable, Hashable, Codable {
            public let url: String
            public let width: Int
            public let height: Int
            
            public init(width: Int, height: Int, url: String) {
                self.url = url
                self.width = width
                self.height = height
            }
        }
        
        public init(
            id: Int,
            type: AttachmentType,
            name: String,
            size: Int,
            metadata: Metadata?
        ) {
            self.id = id
            self.type = type
            self.name = name
            self.size = size
            self.metadata = metadata
        }
    }
    
    public struct LastEdit: Sendable, Hashable, Codable {
        public let userId: Int
        public let username: String
        public let reason: String
        public let date: Date
        
        public init(userId: Int, username: String, reason: String, date: Date) {
            self.userId = userId
            self.username = username
            self.reason = reason
            self.date = date
        }
    }
    
    public struct Author: Sendable, Hashable, Codable {
        public let id: Int
        public let name: String
        public let groupId: Int
        public let avatarUrl: String
        public let lastSeenDate: Date
        public let signature: String
        public let reputationCount: Int
        
        public init(
            id: Int,
            name: String,
            groupId: Int,
            avatarUrl: String,
            lastSeenDate: Date,
            signature: String,
            reputationCount: Int
        ) {
            self.id = id
            self.name = name
            self.groupId = groupId
            self.avatarUrl = avatarUrl
            self.lastSeenDate = lastSeenDate
            self.signature = signature
            self.reputationCount = reputationCount
        }
    }
}

extension Post {
    static let mock = Post(
        id: 12,
        first: false,
        content: .postContent, //"Lorem ipsum...",
        author: Author(
            id: 6176341,
            name: "AirFlare",
            groupId: 8,
            avatarUrl: "https://4pda.to/s/Zy0hVVliEZZvbylgfQy11QiIjvDIhLJBjheakj4yIz2ohhN2F.jpg",
            lastSeenDate: Date(timeIntervalSince1970: 1725706883),
            signature: "",
            reputationCount: 312
        ),
        karma: 0,
        attachments: [
            Attachment(
                id: 14308454,
                type: .image,
                name: "IMG_2369.png",
                size: 62246,
                metadata: Attachment.Metadata(
                    width: 281,
                    height: 500,
                    url: "https://cs2c9f.4pda.ws/14308454.png"
                )
            )
        ],
        createdAt: Date(timeIntervalSince1970: 1725706321),
        lastEdit: LastEdit(
            userId: 6176341,
            username: "AirFlare",
            reason: "for fun",
            date: Date(timeIntervalSince1970: 1725706883)
        )
    )
}

extension String {
    static let postContent = """
[size=4][b][color=royalblue]iPhone 12 / 12 mini - Обсуждение[/color][/b][/size]\n[url=\"https://4pda.to/devdb/apple_iphone_12\"]Описание[/url] | [b]Обсуждение[/b] [url=\"https://4pda.to/forum/index.php?showtopic=1006953&view=getnewpost\"]»[/url] | [url=\"https://4pda.to/forum/index.php?showtopic=1006955\"]Покупка[/url] [url=\"https://4pda.to/forum/index.php?showtopic=1006955&view=getnewpost\"]»[/url] | [url=\"https://4pda.to/forum/index.php?showtopic=1008046\"]Аксессуары[/url] [url=\"https://4pda.to/forum/index.php?showtopic=1008046&view=getnewpost\"]»[/url] | [url=\"https://4pda.to/forum/index.php?showforum=143\"]iOS - Прошивки[/url] | [url=\"https://4pda.to/forum/index.php?showtopic=1010175&view=getlastpost\"]Брак[/url] |  [url=\"https://4pda.to/forum/index.php?showtopic=934612\"]eSIM. Опыт использования[/url] | [url=\"https://www.apple.com/ru/iphone-12/\"]Источник информации[/url]\n[url=\"https://4pda.to/forum/index.php?showtopic=1008658\"]Обсуждение камеры iPhone 12 - 12 Pro Max[/url] | [url=\"https://4pda.to/forum/index.php?showtopic=1010840\"] [color=royalblue]Энерго[/color][color=darkblue]потребление[/color] серии iPhone 12[/url] \n\n[center] [attachment=\"21184536:7F038A09-C68B-4DA4-9F89-B8DCC19406FE.png\"]\niPhone 12 и iPhone 12 Mini идентичны по начинке.\nУстройства имеют всего несколько заметных отличий: размер экрана и ёмкость аккумулятора.[/center]\n\n[size=3]Тема создана для обсуждения работы девайса - рассказываем впечатления от использования и делимся опытом владения данным смартфоном. Дискуссии по поводу [b]возможностей фотокамеры[/b] всех моделей iPhone 12 существует [url=\"https://4pda.to/forum/index.php?showtopic=1008658\"][b][color=royalblue]отдельная тема[/color][/b][/url].\n\nВсе проблемы операционной системы или самого устройства обсуждаются в других темах - информацию об этом читаем ниже.[/size]\n\n[color=red][size=3][b]Вопросы, которые нельзя задавать/обсуждать в теме.[/b][/size][/color]\n[b]1. Проблемы активации устройства[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showtopic=473599\"][color=royalblue][b]Не могу активировать, требует Apple ID[/b][/color][/url]).\n[b]2. Откат прошивки[/b] (информация представлена в теме: [url=\"https://4pda.to/forum/index.php?showtopic=881149)\"][color=royalblue][b]Инструкции по откату (downgrade)[/b][/color][/url]).\n[b]3. Энергопотребление серии iPhone 12[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showtopic=1010840\"][color=royalblue][b]Время жизни аккумулятора iPhone[/b][/color][/url]).\n[b]4. Сравнение и обсуждение производительности процессоров[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showtopic=726557\"][color=royalblue][b]Сравнение процессоров iphone (всех) от tsmc и samsung[/b][/color][/url]).\n[b]5. Необходимость обновления, выбор прошивки и её функции/проблемы[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showforum=143\"][color=royalblue][b]iOS - Прошивки[/b][/color][/url]).\n[b]6. Джейлбрейк (Jailbreak) и всё, что с ним связано[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showforum=143\"][color=royalblue][b]iOS - Прошивки и Джэйлбрэйк[/b][/color][/url]).\n[b]7. Сравнение и выбор устройства [/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showtopic=926984\"][color=royalblue][b]Выбор и сравнение[/b][/color][/url]).\n[b]8. Сторонние вопросы, связанные с программами, операционной системой, iTunes, сетью, комплектующими[/b] (вопросы задаются там: [url=\"https://4pda.to/forum/index.php?showforum=142\"][color=royalblue][b]iOS - Первая помощь[/b][/color][/url]).\n[b]9. Поиск любых программ [/b] (поиск программ там: [url=\"https://4pda.to/forum/index.php?showtopic=103195\"][color=royalblue][b]Поиск программ для iOS[/b][/color][/url]).\n[b]10. Результаты бенчмарков[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showtopic=650565\"][color=royalblue][b]Результаты синтетических тестов[/b][/color][/url]).\n[b]11. Проблемы с отремонтированными устройствами \"Refurbished\"[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showforum=658\"][color=royalblue][b]Брак и ремонт устройств Apple[/b][/color]).[/url]\n[b]12. Вопросы по ремонту устройства[/b] (обсуждение там: [url=\"https://4pda.to/forum/index.php?showtopic=661407\"][color=royalblue][b]iPhone – Ремонт[/b][/color][/url]).\n[b][color=red]Подобные сообщения будут удалены без предупреждения![/color][/b]\n\nВ теме действуют [url=\"https://4pda.to/forum/index.php?act=boardrules\"] [color=royalblue]Правила ресурса 4pda.ru[/color][/url].\nПеред размещением фотографии ознакомьтесь с темой [url=\"https://4pda.to/forum/index.php?showtopic=353146\"][color=royalblue]\"Работа с изображениями на форуме\"[/color][/url].\n\n[spoiler=Характеристики]\n\n[size=3][b]Цвет[/b][/size]\nЧёрный • Белый • PRODUCT)RED • Зелёный • Синий \n[attachment=\"21184537:A73CC6E8-AF77-4A4F-B2C0-A40B53B77F06.png\"]\n\nПередняя панель Ceramic Shield\nЗадняя панель из стекла и корпус из алюминия\n\n[size=3][b]Ёмкость[/b][/size]\n64 Гб\n128 Гб\n256 Гб\n\n[size=3][b]Размеры[/b][/size]\n[attachment=\"21184538:F78D193D-347E-463D-A06D-A7EDE26118CE.jpg\"]\n\niPhone 12\nДлина:146,7 мм • Ширина:71,5 мм •  Толщина:7,4 мм •  Вес:162 г \n\niPhone 12 Mini\nДлина:131,5 мм • Ширина:64,2 мм •  Толщина:7,4 мм •  Вес:133 г \n\n[size=3][b]Дисплей[/b][/size]\n[b]iPhone 12[/b]\nSuper Retina XDR\nOLED, диагональ 6,1 дюйма\n2532Ч1170 пикселей, 460 пикселей на дюйм\n\n[b]iPhone 12 Mini[/b]\nSuper Retina XDR\nOLED, диагональ 5,4 дюйма\n2340Ч1080 пикселей, 476 пикселей на дюйм\n\n[b]Обе модели: [/b]\nПоддержка HDR\nТехнология True Tone\nШирокий цветовой охват (P3)\nТактильный отклик при нажатии\nКонтрастность 2 000 000:1 (стандартная)\nЯркость до 625 кд/мІ (стандартная); до 1200 кд/мІ при просмотре контента в формате HDR\nОлеофобное покрытие, устойчивое к появлению следов от пальцев\nПоддержка одновременного отображения нескольких языков и наборов символов\n\n[size=3][b]Защита от воды и пыли[/b][/size]\nРейтинг IP68 по стандарту IEC 60529\nДопускается погружение в воду на глубину до 6 метров длительностью до 30 минут\n\n[size=3][b]Процессор[/b][/size]\nПроцессор A14 Bionic\nСистема Neural Engine нового поколения\n\n[size=3][b]Камера[/b][/size]\nСистема двух камер 12 Мп: сверхширокоугольная и широкоугольная\nСверхширокоугольная: диафрагма &#x192;/2.4 и угол обзора 120°\nШирокоугольная: диафрагма &#x192;/1.6\nОптический зум 2x на уменьшение\nЦифровой зум до 5x\nРежим «Портрет» с улучшенным эффектом боке и функцией «Глубина»\nПортретное освещение (шесть вариантов: Естественный свет, Студийный свет, Контурный свет, Сценический свет, Сценический свет — ч/б, Светлая тональность — ч/б)\nОптическая стабилизация изображения (широкоугольная камера)\nПятилинзовый объектив (сверхширокоугольная камера); семилинзовый объектив (широкоугольная камера)\nБолее яркая вспышка True Tone с функцией Slow Sync\nПанорамная съёмка (до 63 Мп)\nЗащита объектива сапфировым стеклом\nПоддержка Focus Pixels на всей матрице (широкоугольная камера)\nНочной режим (сверхширокоугольная камера, широкоугольная камера)\nТехнология Deep Fusion (сверхширокоугольная камера, широкоугольная камера)\nРежим Smart HDR 3 с распознаванием сцен\nШирокий цветовой диапазон для фотографий и Live Photos\nКоррекция искажений объектива (сверхширокоугольная камера)\nПередовая система устранения эффекта красных глаз\nАвтоматическая стабилизация изображения\nСерийная съёмка\nПривязка фотографий к месту съёмки\nФорматы изображений: HEIF и JPEG\n\n[size=3][b]Сотовая и беспроводная связь[/b][/size]\n[b]iPhone 12 (A2403)[/b]\n5G NR (диапазоны n1, n2, n3, n5, n7, n8, n12, n20, n25, n28, n38, n40, n41, n66, n77, n78, n79)\nFDD&#x2011;LTE (диапазоны 1, 2, 3, 4, 5, 7, 8, 12, 13, 17, 18, 19, 20, 25, 26, 28, 30, 32, 66)\nTD&#x2011;LTE (диапазоны 34, 38, 39, 40, 41, 42, 46, 48)\nUMTS/HSPA+/DC&#x2011;HSDPA (850, 900, 1700/2100, 1900, 2100 МГц)\nGSM/EDGE (850, 900, 1800, 1900 МГц)\n\n[b]iPhone 12 Mini (A2399)[/b]\n5G NR (диапазоны n1, n2, n3, n5, n7, n8, n12, n20, n25, n28, n38, n40, n41, n66, n77, n78, n79)\nFDD&#x2011;LTE (диапазоны 1, 2, 3, 4, 5, 7, 8, 12, 13, 17, 18, 19, 20, 25, 26, 28, 30, 32, 66)\nTD&#x2011;LTE (диапазоны 34, 38, 39, 40, 41, 42, 46, 48)\nUMTS/HSPA+/DC&#x2011;HSDPA (850, 900, 1700/2100, 1900, 2100 МГц)\nGSM/EDGE (850, 900, 1800, 1900 МГц)\n\n[b]Все модели[/b]\n5G (sub-6 GHz)\nGigabit LTE с технологиями MIMO 4Ч4 и LAA\nWi&#x2011;Fi 6 (802.11ax) с технологией MIMO 2Ч2\nБеспроводная технология Bluetooth 5.0\nМодуль NFC с поддержкой режима считывания\nЭкспресс&#x2011;карты с резервным питанием\n\n[size=3][b]Питание и аккумулятор[/b][/size]\n[b]iPhone 12[/b]\nВоспроизведение видео: до 17 часов\nПросмотр видео в режиме стриминга: до 11 часов\nВоспроизведение аудио: до 65 часов\n\n[b]iPhone 12 Mini[/b]\nВоспроизведение видео: до 15 часов\nПросмотр видео в режиме стриминга: до 10 часов\nВоспроизведение аудио: до 50 часов\n\n[b]Обе модели[/b]\nВстроенный литий&#x2011;ионный аккумулятор\nБеспроводная зарядка с мощностью до 15 Вт при использовании зарядного устройства MagSafe9\nБеспроводная зарядка с мощностью до 7,5 Вт при использовании зарядного устройства стандарта Qi9\nЗарядка от адаптера питания или через USB&#x2011;порт компьютера\nВозможность быстрой зарядки: до 50% заряда за 30 минут10 при использовании адаптера питания мощностью 20 Вт или выше (продаётся отдельно)\n\n[size=3][b]MagSafe[/b][/size]\nБеспроводная зарядка с мощностью до 15 Вт9\nМагниты для зарядки\nНаправляющий магнит\nМодуль NFC для идентификации аксессуаров\nМагнитометр\n\n[size=3][b]Датчики[/b][/size]\nFace ID\nБарометр\nТрёхосевой гироскоп\nАкселерометр\nДатчик приближения\nДатчик внешней освещённости\n\n[size=3][b]SIM-карта[/b][/size]\nПоддержка двух SIM&#x2011;карт (nano&#x2011;SIM и eSIM)\niPhone 12 и iPhone 12 mini не поддерживают карты micro&#x2011;SIM\n\n[size=3][b]Комплектация[/b][/size]\niPhone с iOS 14\nКабель USB&#x2011;C/Lightning\nДокументация\n[attachment=\"21184539:90736BE0-DB96-42AE-BC8F-108ACF4D8D8C.jpg\"]\n\n[/spoiler][spoiler=Обзоры]\n[b][color=red]You[/color]Tube[/b] | [url=\"https://youtu.be/tYvgen-TBSM\"]Обзор iPhone 12 Mini[/url] | от 808\n\n[b]Новости[/b] | [url=\"https://3dnews.ru/1025044/obzor-apple-iphone-12/page-1.html\"]Обзор смартфона Apple iPhone 12: не все включено[/url] | от 3dnews.ru\n[b]Новости[/b] | [url=\"https://hi-tech.mail.ru/review/iphone12_review/#a04\"]Обзор iPhone 12: пожалуй, лучший смартфон Apple «для всех»[/url] | от hi-tech.mail.ru\n[b]Новости[/b] | [url=\"https://www.iphones.ru/iNotes/obzor-iphone-12-10-22-2020\"]Обзор iPhone 12. Прямо топовый для всех и каждого[/url] | от iphones.ru\n\n[/spoiler][spoiler=Отзывы]\n\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101041319\"][b]Indo[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101118466\"][b]Xjack[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101088243\"][b]dred78[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101704074\"][b]lakiss76[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=102164927\"][b]R0iZ[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=102208359\"][b]Jaia[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=102013434\"][b]NightsSpiRiT[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=108955385\"][b]ssskala[/b][/url]\n[b]iPhone 12[/b] | Отзыв от  [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=106549037\"][b]Ravenlll[/b][/url]\n[b]iPhone 12[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=109256132\"][b]artemVAV512[/b][/url]\n\n[b]iPhone 12 Mini[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101682802\"][b]GeneralAladdin[/b][/url]\n[b]iPhone 12 Mini[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101712302\"][b]Alukard137[/b][/url]\n[b]iPhone 12 Mini[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101799244\"][b]Yazid[/b][/url]\n[b]iPhone 12 Mini[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=102137659\"][b]ironman#1[/b][/url]\n[b]iPhone 12 Mini[/b] | Отзыв от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101917611\"][b]marselllago[/b][/url]\n\n[b]iPhone 12 Mini[/b] | Проблемы смартфона | Видео от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101741455\"][b]GeneralAladdin[/b][/url] \n[b]iPhone 12[/b] | Отзыв об экране | Рассказ от [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=102142429\"][b]Opera56[/b][/url] \n\n[/spoiler][spoiler=Дополнительно]\n\nВопросы eSIM обсуждаются в отдельной теме.\n[url=\"https://4pda.to/forum/index.php?showtopic=934612\"]eSIM. Опыт использования[/url]\n\nСравнение размеров экрана 12 Mini с SE, SE2 и 11Pro.\n[url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101117726\"]Обсуждение iPhone 12...  (от Attinum)[/url]\n\nОтличия моделей iPhone 12.\n[url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101073987\"]Первый пример[/url], [url=\"https://4pda.to/forum/index.php?s=&showtopic=998686&view=findpost&p=101068914\"]второй пример[/url], [url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=101061839\"]третий пример+фото[/url] от [b]Indo[/b]\n\n[url=\"https://4pda.to/2020/11/04/377738/\"]Apple урезала возможности зарядки iPhone 12 Mini[/url] | Новости 4pda.ru \n\nКак определить производителя дисплеев?\n[url=\"https://4pda.to/forum/index.php?s=&showtopic=998686&view=findpost&p=101831387\"]Узнаём здесь.[/url]\n\nСписок моделей и частот линейки iPhone 12\n[url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=107204950\"]Обсуждение iPhone 12… (от Нельсон)[/url]\n\nЗамечание про время перевода iPhone 12 в DFU\n[url=\"https://4pda.to/forum/index.php?showtopic=998686&view=findpost&p=118338916\"]Обсуждение iPhone 12... (от Fleymorx)[/url]\n\n[b]Нагрев устройства - это нормально.[/b]\nНагрев и расход батареи не зависит ни от модели девайса, ни от процессора, ни от прошивки. На это влияет масса стандартных причин от активности использования устройства, сигнала сети, запущенных приложений, фоновой синхронизации/обновления данных, яркости экрана и настроек/утяжеления системы до состояния комплектующих и температуры окружающей среды. Все эти составляющие всегда разные даже на одном домашнем устройстве. Также эти показатели отличаются на идентичных устройствах, поэтому никакой систематики не существует.\nНикаких чётких ответов по этому вопросу никогда найти не получалось, не получается и не получится. Никакой важной информации обсуждения нагрева устройства не несут, ничего не объясняют и не показывают.\nНагрев происходил, происходит и будет происходить на всех устройствах, пока не изобретут новые полупроводники, которые не будут выделять тепло. А до тех пор теплоотдача в работе устройств любого производителя является стандартным, логичным и неотъемлемым явлением.\nApple считает нагрев нормальным.\n[url=\"https://support.apple.com/ru-ru/HT201678\"]https://support.apple.com/ru-ru/HT201678[/url]\nВсё рассчитано, предусмотрено и заложено в технические характеристики всех устройств. Если нагрев слишком сильный, то система не допустит проблем и сообщит об этом, но до этого момента на подобное явление не нужно обращать никакого внимания.\n\n[b][color=\"#000000\"]ШИМ на устройствах Apple[/color][/b]\nВопрос ШИМ относится ко всем современным моделям смартфонов вне зависимости от производителя. Все сообщения по типу \"смотрю на экран - начинают болеть глаза и голова\" показывают исключительно индивидуальное восприятие. С недавнего времени у пользователей появляются мнения, что ШИМ вообще не при чём, а при проблемах восприятия экрана нужно проверить зрение у специалиста. \nЧтобы лично изучить восприятие к мерцанию экрана, нужно самостоятельно взять в руки смартфон и 10-20 минут [b]попользоваться в разных режимах яркости экрана[/b] - это важно, так как в магазинах у всех демо-смартфонов на витринах выставлена максимальная яркость, при которой ШИМ отсутствует. Чем меньше яркость, тем больше мерцание - именно так нужно проверять. \nТакже можно изучить хорошую статью [url=\"https://www.iphones.ru/iNotes/tak-vreden-shim-ili-net-zakryvaem-vopros-o-mercanii-displeya-iphone-raz-i-navsegda-04-02-2022\"]по вопросу ШИМ[/url] на [b]iphones.ru[/b]\nНо всё нужно проверять исключительно своим личным опытом. Чужие мнения, статьи, технические замеры и прочее могут быть бесполезными. \n[url=\"https://4pda.to/forum/index.php?showtopic=1060594\"]Обсуждение шим на всех устройствах в отдельной теме[/url]\n\n[/spoiler]\n[b]В теме нет куратора. Отправляйте заявки на рассмотрение через раздел [url=\"https://4pda.to/forum/index.php?showforum=958\"]\"Хочу стать куратором\"[/url][/b]
"""
}
