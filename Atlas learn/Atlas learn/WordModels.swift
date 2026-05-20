//
//  WordModels.swift
//  Atlas learn
//

import Foundation
import SwiftUI

enum AppLanguage: String, CaseIterable, Codable, Identifiable {
    case russian
    case english

    var id: String { rawValue }

    var nativeTitle: String {
        switch self {
        case .russian: "Русский"
        case .english: "English"
        }
    }

    var shortTitle: String {
        switch self {
        case .russian: "RU"
        case .english: "EN"
        }
    }

    func text(ru: String, en: String) -> String {
        self == .russian ? ru : en
    }
}

enum LearningLevel: String, CaseIterable, Codable, Identifiable, Comparable {
    case beginner
    case elementary
    case intermediate
    case upperIntermediate
    case advanced

    var id: String { rawValue }

    var order: Int {
        switch self {
        case .beginner: 0
        case .elementary: 1
        case .intermediate: 2
        case .upperIntermediate: 3
        case .advanced: 4
        }
    }

    var tag: String {
        switch self {
        case .beginner: "A1"
        case .elementary: "A2"
        case .intermediate: "B1"
        case .upperIntermediate: "B2"
        case .advanced: "C1"
        }
    }

    var englishTitle: String {
        switch self {
        case .beginner: "Beginner"
        case .elementary: "Elementary"
        case .intermediate: "Intermediate"
        case .upperIntermediate: "Upper Intermediate"
        case .advanced: "Advanced"
        }
    }

    var russianTitle: String {
        switch self {
        case .beginner: "Начальный"
        case .elementary: "Базовый"
        case .intermediate: "Средний"
        case .upperIntermediate: "Выше среднего"
        case .advanced: "Продвинутый"
        }
    }

    func title(for language: AppLanguage) -> String {
        language.text(ru: russianTitle, en: englishTitle)
    }

    static func < (lhs: LearningLevel, rhs: LearningLevel) -> Bool {
        lhs.order < rhs.order
    }

    static func calibrated(from selected: LearningLevel, knownCount: Int, total: Int) -> LearningLevel {
        guard total > 0 else { return selected }

        let ratio = Double(knownCount) / Double(total)
        let shift: Int

        if ratio < 0.25 {
            shift = -1
        } else if ratio > 0.75 {
            shift = 1
        } else {
            shift = 0
        }

        let index = max(0, min(Self.allCases.count - 1, selected.order + shift))
        return Self.allCases[index]
    }
}

enum SpeechVoiceOption: String, CaseIterable, Codable, Identifiable {
    case american
    case british
    case australian
    case irish
    case southAfrican

    var id: String { rawValue }

    var languageCode: String {
        switch self {
        case .american: "en-US"
        case .british: "en-GB"
        case .australian: "en-AU"
        case .irish: "en-IE"
        case .southAfrican: "en-ZA"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .american: language.text(ru: "Американский", en: "American")
        case .british: language.text(ru: "Британский", en: "British")
        case .australian: language.text(ru: "Австралийский", en: "Australian")
        case .irish: language.text(ru: "Ирландский", en: "Irish")
        case .southAfrican: language.text(ru: "Южноафриканский", en: "South African")
        }
    }

    func subtitle(for language: AppLanguage) -> String {
        switch self {
        case .american: language.text(ru: "Четкое нейтральное произношение", en: "Clear neutral pronunciation")
        case .british: language.text(ru: "Мягкий британский акцент", en: "Soft British accent")
        case .australian: language.text(ru: "Легкий австралийский акцент", en: "Light Australian accent")
        case .irish: language.text(ru: "Живой ирландский акцент", en: "Lively Irish accent")
        case .southAfrican: language.text(ru: "Спокойный южноафриканский акцент", en: "Calm South African accent")
        }
    }
}

struct WordEntry: Codable, Hashable, Identifiable {
    let id: String
    let english: String
    let russian: String
    let partOfSpeech: String
    let ipa: String
    let definitionEN: String
    let definitionRU: String
    let exampleEN: String
    let exampleRU: String
    let level: LearningLevel
    let topic: String

    func definition(for language: AppLanguage) -> String {
        language.text(ru: definitionRU, en: definitionEN)
    }

    func example(for language: AppLanguage) -> String {
        language.text(ru: exampleRU, en: exampleEN)
    }
}

struct AtlasProfile: Codable, Equatable {
    var appLanguage: AppLanguage
    var level: LearningLevel
    var dailyGoal: Int
    var voiceID: SpeechVoiceOption? = .american
    var selectedTopics: [String]
    var unknownWordIDs: [String]
    var savedWordIDs: [String]
    var favoriteWordIDs: [String]
    var completedTodayIDs: [String]
    var streak: Int
    var xp: Int

    static let `default` = AtlasProfile(
        appLanguage: .russian,
        level: .elementary,
        dailyGoal: 5,
        selectedTopics: ["Everyday", "Work", "Emotions"],
        unknownWordIDs: [],
        savedWordIDs: [],
        favoriteWordIDs: [],
        completedTodayIDs: [],
        streak: 0,
        xp: 0
    )

    var dailyWords: [WordEntry] {
        WordBank.dailyWords(for: self)
    }

    var selectedSpeechVoice: SpeechVoiceOption {
        voiceID ?? .american
    }

    mutating func toggleSaved(_ id: String) {
        savedWordIDs.toggle(id)
    }

    mutating func toggleFavorite(_ id: String) {
        favoriteWordIDs.toggle(id)
    }

    mutating func addUnknown(_ id: String) {
        unknownWordIDs.appendUnique(id)
    }

    mutating func markCompleted(_ id: String) {
        completedTodayIDs.appendUnique(id)
    }
}

extension Array where Element: Equatable {
    mutating func appendUnique(_ element: Element) {
        guard !contains(element) else { return }
        append(element)
    }

    mutating func toggle(_ element: Element) {
        if let index = firstIndex(of: element) {
            remove(at: index)
        } else {
            append(element)
        }
    }
}

enum WordBank {
    static let topics = ["Everyday", "Work", "Study", "Emotions", "Travel", "Business"]

    static let all: [WordEntry] = [
        w("focus", "focus", "фокус", "noun", "/FOH-kus/", "Careful attention to one thing.", "Внимание, направленное на одну задачу.", "Deep work needs focus.", "Глубокая работа требует фокуса.", .beginner, "Everyday"),
        w("goal", "goal", "цель", "noun", "/gohl/", "Something you want to achieve.", "То, чего ты хочешь достичь.", "My goal is to read daily.", "Моя цель - читать каждый день.", .beginner, "Everyday"),
        w("habit", "habit", "привычка", "noun", "/HAB-it/", "A regular action you repeat.", "Действие, которое ты регулярно повторяешь.", "Practice became a habit.", "Практика стала привычкой.", .beginner, "Everyday"),
        w("effort", "effort", "усилие", "noun", "/EF-ert/", "Energy used to do something.", "Энергия, потраченная на действие.", "Small effort every day matters.", "Маленькое усилие каждый день важно.", .beginner, "Study"),
        w("improve", "improve", "улучшать", "verb", "/im-PROOV/", "To become better.", "Становиться лучше.", "I want to improve my English.", "Я хочу улучшить английский.", .beginner, "Study"),
        w("remember", "remember", "помнить", "verb", "/ri-MEM-ber/", "To keep something in your mind.", "Сохранять что-то в памяти.", "I remember this word.", "Я помню это слово.", .beginner, "Study"),
        w("practice", "practice", "тренироваться", "verb", "/PRAK-tis/", "To repeat a skill to get better.", "Повторять навык, чтобы стать лучше.", "Practice the words aloud.", "Тренируй слова вслух.", .beginner, "Study"),
        w("choice", "choice", "выбор", "noun", "/choys/", "An option you can select.", "Вариант, который можно выбрать.", "You made a smart choice.", "Ты сделал умный выбор.", .beginner, "Everyday"),
        w("mistake", "mistake", "ошибка", "noun", "/mi-STAYK/", "Something done incorrectly.", "Что-то сделанное неправильно.", "A mistake can teach you.", "Ошибка может тебя научить.", .beginner, "Study"),
        w("useful", "useful", "полезный", "adjective", "/YOOS-ful/", "Helpful or practical.", "Полезный или практичный.", "This phrase is useful.", "Эта фраза полезна.", .beginner, "Everyday"),
        w("honest", "honest", "честный", "adjective", "/ON-ist/", "Telling the truth.", "Говорящий правду.", "Give me an honest answer.", "Дай мне честный ответ.", .elementary, "Emotions"),
        w("curious", "curious", "любознательный", "adjective", "/KYUR-ee-us/", "Wanting to know more.", "Желающий узнать больше.", "Curious people ask questions.", "Любознательные люди задают вопросы.", .elementary, "Study"),
        w("patient", "patient", "терпеливый", "adjective", "/PAY-shent/", "Able to wait calmly.", "Способный спокойно ждать.", "Be patient with yourself.", "Будь терпелив к себе.", .elementary, "Emotions"),
        w("borrow", "borrow", "одалживать", "verb", "/BOR-oh/", "To take something and return it later.", "Взять что-то с возвратом.", "Can I borrow your book?", "Можно одолжить твою книгу?", .elementary, "Everyday"),
        w("advice", "advice", "совет", "noun", "/ad-VYS/", "A suggestion about what to do.", "Предложение о том, как поступить.", "Her advice helped me.", "Ее совет мне помог.", .elementary, "Work"),
        w("arrange", "arrange", "организовать", "verb", "/uh-RAYNJ/", "To plan or put in order.", "Запланировать или привести в порядок.", "Let's arrange a meeting.", "Давай организуем встречу.", .elementary, "Work"),
        w("avoid", "avoid", "избегать", "verb", "/uh-VOYD/", "To stay away from something.", "Держаться подальше от чего-то.", "Avoid repeating the same mistake.", "Избегай повторения той же ошибки.", .elementary, "Everyday"),
        w("compare", "compare", "сравнивать", "verb", "/kum-PAIR/", "To look for similarities and differences.", "Искать сходства и различия.", "Compare the two answers.", "Сравни два ответа.", .elementary, "Study"),
        w("support", "support", "поддержка", "noun", "/suh-PORT/", "Help given to someone.", "Помощь, оказанная кому-то.", "Your support means a lot.", "Твоя поддержка очень важна.", .elementary, "Emotions"),
        w("confident", "confident", "уверенный", "adjective", "/KON-fi-dent/", "Feeling sure about your ability.", "Уверенный в своих силах.", "She sounds confident.", "Она звучит уверенно.", .elementary, "Work"),
        w("concise", "concise", "краткий", "adjective", "/kun-SYS/", "Using few words clearly.", "Ясный и немногословный.", "Write a concise answer.", "Напиши краткий ответ.", .intermediate, "Work"),
        w("reluctant", "reluctant", "неохотный", "adjective", "/ri-LUK-tent/", "Not willing to do something.", "Не желающий что-то делать.", "He was reluctant to speak.", "Он неохотно говорил.", .intermediate, "Emotions"),
        w("resilient", "resilient", "стойкий", "adjective", "/ri-ZIL-yent/", "Able to recover after difficulty.", "Способный восстановиться после трудностей.", "A resilient learner keeps going.", "Стойкий ученик продолжает идти.", .intermediate, "Study"),
        w("abundant", "abundant", "обильный", "adjective", "/uh-BUN-dent/", "More than enough.", "Более чем достаточный.", "The city has abundant options.", "В городе обильный выбор.", .intermediate, "Travel"),
        w("emerge", "emerge", "появляться", "verb", "/i-MERJ/", "To appear or become known.", "Появляться или становиться известным.", "A pattern began to emerge.", "Начала появляться закономерность.", .intermediate, "Study"),
        w("imply", "imply", "подразумевать", "verb", "/im-PLY/", "To suggest without saying directly.", "Намекать, не говоря прямо.", "What does this sentence imply?", "Что подразумевает это предложение?", .intermediate, "Study"),
        w("maintain", "maintain", "поддерживать", "verb", "/mayn-TAYN/", "To keep something in good condition.", "Сохранять что-то в хорошем состоянии.", "Maintain your learning streak.", "Поддерживай серию обучения.", .intermediate, "Everyday"),
        w("notice", "notice", "замечать", "verb", "/NOH-tis/", "To become aware of something.", "Осознать или увидеть что-то.", "Notice how the word is used.", "Заметь, как используется слово.", .intermediate, "Study"),
        w("approach", "approach", "подход", "noun", "/uh-PROHCH/", "A way of dealing with something.", "Способ решения или отношения к чему-то.", "Try a new approach.", "Попробуй новый подход.", .intermediate, "Work"),
        w("reliable", "reliable", "надежный", "adjective", "/ri-LY-uh-bul/", "Able to be trusted.", "Такой, которому можно доверять.", "This source is reliable.", "Этот источник надежный.", .intermediate, "Work"),
        w("vivid", "vivid", "яркий", "adjective", "/VIV-id/", "Clear, strong, and detailed.", "Ясный, сильный и детальный.", "She gave a vivid example.", "Она привела яркий пример.", .intermediate, "Study"),
        w("pursue", "pursue", "добиваться", "verb", "/per-SOO/", "To try to achieve something.", "Стараться достичь чего-то.", "Pursue the goal patiently.", "Добивайся цели терпеливо.", .intermediate, "Work"),
        w("subtle", "subtle", "тонкий", "adjective", "/SUT-ul/", "Not obvious, delicate.", "Неочевидный, деликатный.", "There is a subtle difference.", "Есть тонкое различие.", .intermediate, "Study"),
        w("expand", "expand", "расширять", "verb", "/ik-SPAND/", "To make larger or wider.", "Делать больше или шире.", "Expand your vocabulary.", "Расширяй словарный запас.", .intermediate, "Study"),
        w("reticence", "reticence", "сдержанность", "noun", "/RET-i-sens/", "Being quiet and not sharing thoughts easily.", "Сдержанность, нежелание легко делиться мыслями.", "His reticence made the room feel tense.", "Его сдержанность создала напряжение.", .upperIntermediate, "Emotions"),
        w("meticulous", "meticulous", "дотошный", "adjective", "/muh-TIK-yuh-lus/", "Very careful and precise.", "Очень внимательный и точный.", "She keeps meticulous notes.", "Она ведет дотошные заметки.", .upperIntermediate, "Work"),
        w("coherent", "coherent", "связный", "adjective", "/koh-HEER-ent/", "Logical and easy to understand.", "Логичный и понятный.", "Make your argument coherent.", "Сделай аргумент связным.", .upperIntermediate, "Study"),
        w("alleviate", "alleviate", "облегчать", "verb", "/uh-LEE-vee-ayt/", "To make pain or a problem less severe.", "Смягчать боль или проблему.", "A short break can alleviate stress.", "Короткий перерыв может облегчить стресс.", .upperIntermediate, "Emotions"),
        w("inevitable", "inevitable", "неизбежный", "adjective", "/in-EV-i-tuh-bul/", "Impossible to avoid.", "Такой, которого невозможно избежать.", "Some mistakes are inevitable.", "Некоторые ошибки неизбежны.", .upperIntermediate, "Everyday"),
        w("profound", "profound", "глубокий", "adjective", "/proh-FOWND/", "Very great or meaningful.", "Очень значительный или глубокий.", "The book had a profound effect.", "Книга оказала глубокое влияние.", .upperIntermediate, "Study"),
        w("ambiguity", "ambiguity", "двусмысленность", "noun", "/am-bi-GYOO-i-tee/", "The quality of having more than one meaning.", "Наличие более чем одного значения.", "The ambiguity confused everyone.", "Двусмысленность всех запутала.", .upperIntermediate, "Work"),
        w("scrutiny", "scrutiny", "пристальное изучение", "noun", "/SKROO-tin-ee/", "Careful and detailed examination.", "Тщательная и детальная проверка.", "The plan is under scrutiny.", "План находится под пристальным изучением.", .upperIntermediate, "Business"),
        w("mundane", "mundane", "обыденный", "adjective", "/mun-DAYN/", "Ordinary and not exciting.", "Обычный и неинтересный.", "Even mundane tasks can teach discipline.", "Даже обыденные задачи учат дисциплине.", .upperIntermediate, "Everyday"),
        w("articulate", "articulate", "ясно выражать", "verb", "/ar-TIK-yuh-layt/", "To express ideas clearly.", "Ясно выражать идеи.", "Articulate your opinion calmly.", "Ясно вырази свое мнение спокойно.", .upperIntermediate, "Work"),
        w("endeavor", "endeavor", "стремление", "noun", "/en-DEV-er/", "A serious attempt to do something.", "Серьезная попытка что-то сделать.", "Learning is a lifelong endeavor.", "Обучение - стремление на всю жизнь.", .upperIntermediate, "Study"),
        w("nuance", "nuance", "нюанс", "noun", "/NOO-ahns/", "A small but important difference.", "Маленькое, но важное различие.", "This word has a useful nuance.", "У этого слова есть полезный нюанс.", .upperIntermediate, "Study"),
        w("serendipity", "serendipity", "счастливая случайность", "noun", "/ser-en-DIP-i-tee/", "Finding something good by chance.", "Случайное открытие чего-то хорошего.", "Their meeting was pure serendipity.", "Их встреча была счастливой случайностью.", .advanced, "Everyday"),
        w("ubiquitous", "ubiquitous", "повсеместный", "adjective", "/yoo-BIK-wi-tus/", "Present everywhere.", "Присутствующий повсюду.", "Smartphones are ubiquitous.", "Смартфоны повсеместны.", .advanced, "Business"),
        w("ephemeral", "ephemeral", "мимолетный", "adjective", "/i-FEM-er-ul/", "Lasting for a very short time.", "Длящийся очень короткое время.", "The mood was ephemeral.", "Настроение было мимолетным.", .advanced, "Emotions"),
        w("benevolent", "benevolent", "доброжелательный", "adjective", "/buh-NEV-uh-lent/", "Kind and willing to help.", "Добрый и готовый помочь.", "A benevolent mentor guided them.", "Доброжелательный наставник их вел.", .advanced, "Work"),
        w("exacerbate", "exacerbate", "усугублять", "verb", "/ig-ZAS-er-bayt/", "To make a problem worse.", "Делать проблему хуже.", "Stress can exacerbate confusion.", "Стресс может усугубить путаницу.", .advanced, "Emotions"),
        w("juxtapose", "juxtapose", "сопоставлять", "verb", "/JUK-stuh-pohz/", "To place things side by side for contrast.", "Размещать рядом для сравнения.", "Juxtapose the two examples.", "Сопоставь два примера.", .advanced, "Study"),
        w("elicit", "elicit", "вызывать", "verb", "/i-LIS-it/", "To draw out a response.", "Вызывать реакцию или ответ.", "The question elicited a smile.", "Вопрос вызвал улыбку.", .advanced, "Emotions"),
        w("perspicacious", "perspicacious", "проницательный", "adjective", "/per-spi-KAY-shus/", "Able to understand things quickly and clearly.", "Способный быстро и ясно понимать.", "Her analysis was perspicacious.", "Ее анализ был проницательным.", .advanced, "Business"),
        w("ostensible", "ostensible", "мнимый", "adjective", "/ah-STEN-suh-bul/", "Appearing true but not necessarily real.", "Кажущийся истинным, но не обязательно реальный.", "The ostensible reason was budget.", "Мнимой причиной был бюджет.", .advanced, "Business"),
        w("clandestine", "clandestine", "тайный", "adjective", "/klan-DES-tin/", "Done secretly.", "Сделанный тайно.", "They held a clandestine meeting.", "Они провели тайную встречу.", .advanced, "Business"),
        w("paradigm", "paradigm", "парадигма", "noun", "/PAIR-uh-dym/", "A model or pattern of thinking.", "Модель или образец мышления.", "The discovery changed the paradigm.", "Открытие изменило парадигму.", .advanced, "Study"),
        w("ambivalent", "ambivalent", "двойственный", "adjective", "/am-BIV-uh-lent/", "Having mixed feelings.", "Испытывающий смешанные чувства.", "I feel ambivalent about the offer.", "У меня двойственное чувство насчет предложения.", .advanced, "Emotions"),
        w("quintessential", "quintessential", "типичный", "adjective", "/kwin-tuh-SEN-shul/", "The most perfect example of something.", "Самый характерный пример чего-то.", "It was a quintessential city cafe.", "Это было типичное городское кафе.", .advanced, "Travel")
    ]

    static let assessmentWords: [WordEntry] = [
        all[0], all[12], all[20], all[34], all[45], all[52]
    ]

    static func entry(id: String) -> WordEntry? {
        all.first { $0.id == id }
    }

    static func topicTitle(_ topic: String, for language: AppLanguage) -> String {
        switch topic {
        case "Everyday": language.text(ru: "Каждый день", en: "Everyday")
        case "Work": language.text(ru: "Работа", en: "Work")
        case "Study": language.text(ru: "Учеба", en: "Study")
        case "Emotions": language.text(ru: "Эмоции", en: "Emotions")
        case "Travel": language.text(ru: "Путешествия", en: "Travel")
        case "Business": language.text(ru: "Бизнес", en: "Business")
        default: topic
        }
    }

    static func dailyWords(for profile: AtlasProfile) -> [WordEntry] {
        let unknown = profile.unknownWordIDs.compactMap { id in
            all.first { $0.id == id }
        }
        let selectedTopics = Set(profile.selectedTopics)
        let levelCeiling = min(LearningLevel.advanced.order, profile.level.order + 1)

        var candidates = all.filter { word in
            word.level.order <= levelCeiling && (selectedTopics.isEmpty || selectedTopics.contains(word.topic))
        }

        if candidates.count < profile.dailyGoal {
            candidates = all.filter { $0.level.order <= levelCeiling }
        }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let rotatedCandidates = rotated(candidates, seed: day + profile.level.order * 7)

        var result: [WordEntry] = []

        for word in unknown + rotatedCandidates {
            guard !result.contains(where: { $0.id == word.id }) else { continue }
            result.append(word)

            if result.count == profile.dailyGoal {
                break
            }
        }

        return result
    }

    static func translationChoices(for word: WordEntry) -> [String] {
        let sameLevel = all
            .filter { $0.id != word.id && $0.level == word.level }
            .map(\.russian)

        let fallback = all
            .filter { $0.id != word.id }
            .map(\.russian)

        let pool = Array(Set(sameLevel.count >= 3 ? sameLevel : fallback)).sorted()
        var choices = Array(rotated(pool, seed: seed(for: word.id)).prefix(3))
        let insertIndex = choices.isEmpty ? 0 : seed(for: word.english) % (choices.count + 1)
        choices.insert(word.russian, at: insertIndex)
        return Array(choices.prefix(4))
    }

    private static func w(
        _ id: String,
        _ english: String,
        _ russian: String,
        _ partOfSpeech: String,
        _ ipa: String,
        _ definitionEN: String,
        _ definitionRU: String,
        _ exampleEN: String,
        _ exampleRU: String,
        _ level: LearningLevel,
        _ topic: String
    ) -> WordEntry {
        WordEntry(
            id: id,
            english: english,
            russian: russian,
            partOfSpeech: partOfSpeech,
            ipa: ipa,
            definitionEN: definitionEN,
            definitionRU: definitionRU,
            exampleEN: exampleEN,
            exampleRU: exampleRU,
            level: level,
            topic: topic
        )
    }

    private static func rotated<T>(_ items: [T], seed: Int) -> [T] {
        guard !items.isEmpty else { return [] }
        let offset = abs(seed) % items.count
        return Array(items[offset..<items.count]) + Array(items[0..<offset])
    }

    private static func seed(for value: String) -> Int {
        value.unicodeScalars.reduce(0) { partialResult, scalar in
            (partialResult + Int(scalar.value)) % 10_000
        }
    }
}
