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
    case a1
    case a2
    case b1
    case b2
    case c1
    case c2

    var id: String { rawValue }

    var order: Int {
        switch self {
        case .a1: 0
        case .a2: 1
        case .b1: 2
        case .b2: 3
        case .c1: 4
        case .c2: 5
        }
    }

    var tag: String {
        switch self {
        case .a1: "A1"
        case .a2: "A2"
        case .b1: "B1"
        case .b2: "B2"
        case .c1: "C1"
        case .c2: "C2"
        }
    }

    var scoreRange: ClosedRange<Int> {
        switch self {
        case .a1: 0...29
        case .a2: 30...59
        case .b1: 60...99
        case .b2: 100...129
        case .c1: 130...144
        case .c2: 145...160
        }
    }

    var scoreStart: Int { scoreRange.lowerBound }

    var englishTitle: String {
        switch self {
        case .a1: "Beginner"
        case .a2: "Elementary"
        case .b1: "Intermediate"
        case .b2: "Upper Intermediate"
        case .c1: "Advanced"
        case .c2: "Proficient"
        }
    }

    var russianTitle: String {
        switch self {
        case .a1: "Начальный"
        case .a2: "Базовый"
        case .b1: "Средний"
        case .b2: "Выше среднего"
        case .c1: "Продвинутый"
        case .c2: "Профессиональный"
        }
    }

    func title(for language: AppLanguage) -> String {
        language.text(ru: russianTitle, en: englishTitle)
    }

    var shortCanDoRU: String {
        switch self {
        case .a1: "Простые фразы, знакомство, базовые вопросы."
        case .a2: "Рутинные темы, покупки, поездки, семья, работа."
        case .b1: "Знакомые ситуации, рассказы, планы и мнения."
        case .b2: "Сложные темы, аргументы, новости и работа."
        case .c1: "Длинные тексты, нюансы, гибкая речь."
        case .c2: "Почти всё на слух и в тексте, точная речь."
        }
    }

    var next: LearningLevel {
        LearningLevel.allCases[min(order + 1, LearningLevel.allCases.count - 1)]
    }

    static func < (lhs: LearningLevel, rhs: LearningLevel) -> Bool {
        lhs.order < rhs.order
    }

    static func from(score: Int) -> LearningLevel {
        let clamped = max(0, min(score, 160))
        return allCases.first { $0.scoreRange.contains(clamped) } ?? .c2
    }

    static func calibrated(from selected: LearningLevel, correctCount: Int, total: Int) -> (level: LearningLevel, score: Int) {
        guard total > 0 else { return (selected, selected.scoreStart) }

        let accuracy = Double(correctCount) / Double(total)
        let base = selected.scoreStart + Int(Double(selected.scoreRange.count) * 0.45)
        let shift = Int((accuracy - 0.5) * 58)
        let score = max(0, min(160, base + shift))
        return (from(score: score), score)
    }

    static func calibrated(from selected: LearningLevel, knownCount: Int, total: Int) -> LearningLevel {
        calibrated(from: selected, correctCount: knownCount, total: total).level
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self).lowercased()

        switch raw {
        case "a1", "beginner":
            self = .a1
        case "a2", "elementary":
            self = .a2
        case "b1", "intermediate":
            self = .b1
        case "b2", "upperintermediate", "upper_intermediate", "upper-intermediate":
            self = .b2
        case "c1", "advanced":
            self = .c1
        case "c2", "proficient":
            self = .c2
        default:
            self = .a2
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

enum PracticeMode: String, CaseIterable, Codable, Identifiable {
    case translateChoice
    case synonymMatch
    case sentenceBuilder
    case clozeChoice

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .translateChoice: "text.bubble"
        case .synonymMatch: "link"
        case .sentenceBuilder: "square.grid.3x1.below.line.grid.1x2"
        case .clozeChoice: "text.cursor"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .translateChoice:
            language.text(ru: "Перевод", en: "Translation")
        case .synonymMatch:
            language.text(ru: "Синоним", en: "Synonym")
        case .sentenceBuilder:
            language.text(ru: "Собери фразу", en: "Build sentence")
        case .clozeChoice:
            language.text(ru: "Пропуск", en: "Fill the blank")
        }
    }

    func subtitle(for language: AppLanguage) -> String {
        switch self {
        case .translateChoice:
            language.text(ru: "Выбери русский перевод", en: "Choose the Russian meaning")
        case .synonymMatch:
            language.text(ru: "Найди близкое английское слово", en: "Find the closest English word")
        case .sentenceBuilder:
            language.text(ru: "Расставь плитки по порядку", en: "Put the tiles in order")
        case .clozeChoice:
            language.text(ru: "Вставь слово в контекст", en: "Use the word in context")
        }
    }

    var xpReward: Int {
        switch self {
        case .translateChoice: 10
        case .synonymMatch: 12
        case .sentenceBuilder: 15
        case .clozeChoice: 14
        }
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
    let synonyms: [String]
    let sentenceTiles: [String]
    let clozeSentence: String

    var cefrLevel: LearningLevel { level }

    var hasReadableRussian: Bool {
        !russian.localizedCaseInsensitiveContains("учебное слово:") &&
            russian.range(of: #"\p{Cyrillic}"#, options: .regularExpression) != nil
    }

    func definition(for language: AppLanguage) -> String {
        language.text(ru: definitionRU, en: definitionEN)
    }

    func example(for language: AppLanguage) -> String {
        language.text(ru: exampleRU, en: exampleEN)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case english
        case russian
        case partOfSpeech
        case ipa
        case definitionEN
        case definitionRU
        case exampleEN
        case exampleRU
        case level
        case cefrLevel
        case topic
        case synonyms
        case sentenceTiles
        case clozeSentence
    }

    init(
        id: String,
        english: String,
        russian: String,
        partOfSpeech: String,
        ipa: String,
        definitionEN: String,
        definitionRU: String,
        exampleEN: String,
        exampleRU: String,
        level: LearningLevel,
        topic: String,
        synonyms: [String],
        sentenceTiles: [String],
        clozeSentence: String
    ) {
        self.id = id
        self.english = english
        self.russian = russian
        self.partOfSpeech = partOfSpeech
        self.ipa = ipa
        self.definitionEN = definitionEN
        self.definitionRU = definitionRU
        self.exampleEN = exampleEN
        self.exampleRU = exampleRU
        self.level = level
        self.topic = topic
        self.synonyms = synonyms
        self.sentenceTiles = sentenceTiles
        self.clozeSentence = clozeSentence
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english)
        russian = try container.decode(String.self, forKey: .russian)
        partOfSpeech = try container.decodeIfPresent(String.self, forKey: .partOfSpeech) ?? "word"
        ipa = try container.decodeIfPresent(String.self, forKey: .ipa) ?? "/\(english)/"
        definitionEN = try container.decodeIfPresent(String.self, forKey: .definitionEN) ?? "A useful English word for everyday communication."
        definitionRU = try container.decodeIfPresent(String.self, forKey: .definitionRU) ?? "Полезное английское слово для общения."
        exampleEN = try container.decodeIfPresent(String.self, forKey: .exampleEN) ?? "I can use \(english) today."
        exampleRU = try container.decodeIfPresent(String.self, forKey: .exampleRU) ?? "Я могу использовать \(english) сегодня."
        level = try container.decodeIfPresent(LearningLevel.self, forKey: .level)
            ?? container.decodeIfPresent(LearningLevel.self, forKey: .cefrLevel)
            ?? .a2
        topic = try container.decodeIfPresent(String.self, forKey: .topic) ?? "Everyday"
        synonyms = try container.decodeIfPresent([String].self, forKey: .synonyms) ?? []
        sentenceTiles = try container.decodeIfPresent([String].self, forKey: .sentenceTiles) ?? exampleEN.split(separator: " ").map(String.init)
        clozeSentence = try container.decodeIfPresent(String.self, forKey: .clozeSentence) ?? exampleEN.replacingOccurrences(of: english, with: "____")
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(english, forKey: .english)
        try container.encode(russian, forKey: .russian)
        try container.encode(partOfSpeech, forKey: .partOfSpeech)
        try container.encode(ipa, forKey: .ipa)
        try container.encode(definitionEN, forKey: .definitionEN)
        try container.encode(definitionRU, forKey: .definitionRU)
        try container.encode(exampleEN, forKey: .exampleEN)
        try container.encode(exampleRU, forKey: .exampleRU)
        try container.encode(level, forKey: .level)
        try container.encode(topic, forKey: .topic)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encode(sentenceTiles, forKey: .sentenceTiles)
        try container.encode(clozeSentence, forKey: .clozeSentence)
    }
}

struct WordMemory: Codable, Equatable {
    var correctCount: Int
    var wrongCount: Int
    var streak: Int
    var mastery: Int
    var lastPracticedAt: Date?
    var dueAt: Date?

    static let fresh = WordMemory(
        correctCount: 0,
        wrongCount: 0,
        streak: 0,
        mastery: 0,
        lastPracticedAt: nil,
        dueAt: nil
    )

    var totalAttempts: Int { correctCount + wrongCount }

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctCount) / Double(totalAttempts)
    }

    func isDue(on date: Date = Date()) -> Bool {
        guard let dueAt else { return totalAttempts > 0 && mastery < 60 }
        return dueAt <= date
    }
}

struct DailyProgress: Codable, Equatable, Identifiable {
    var id: String { dateKey }
    var dateKey: String
    var completedWordIDs: [String]
    var xp: Int
    var correct: Int
    var wrong: Int
    var dueCountAtStart: Int

    static func empty(for dateKey: String) -> DailyProgress {
        DailyProgress(dateKey: dateKey, completedWordIDs: [], xp: 0, correct: 0, wrong: 0, dueCountAtStart: 0)
    }

    var total: Int { correct + wrong }

    var accuracy: Double {
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }
}

struct PracticeRecord: Codable, Equatable, Identifiable {
    let id: UUID
    let date: Date
    let wordID: String
    let wordEnglish: String
    let mode: PracticeMode
    let isCorrect: Bool
    let xp: Int
    let level: LearningLevel
}

struct AtlasProfile: Codable, Equatable {
    var appLanguage: AppLanguage
    var currentLevel: LearningLevel
    var score0To160: Int
    var dailyGoal: Int
    var voiceID: SpeechVoiceOption?
    var selectedTopics: [String]
    var unknownWordIDs: [String]
    var savedWordIDs: [String]
    var favoriteWordIDs: [String]
    var completedTodayIDs: [String]
    var wordProgress: [String: WordMemory]
    var dailyProgress: [String: DailyProgress]
    var practiceHistory: [PracticeRecord]
    var lastStudyDateKey: String
    var streak: Int
    var xp: Int

    var level: LearningLevel {
        get { currentLevel }
        set {
            currentLevel = newValue
            score0To160 = max(score0To160, newValue.scoreStart)
        }
    }

    static let `default` = AtlasProfile(
        appLanguage: .russian,
        currentLevel: .a2,
        score0To160: LearningLevel.a2.scoreStart,
        dailyGoal: 7,
        selectedTopics: ["Everyday", "Work", "Study"],
        unknownWordIDs: [],
        savedWordIDs: [],
        favoriteWordIDs: [],
        completedTodayIDs: [],
        wordProgress: [:],
        dailyProgress: [:],
        practiceHistory: [],
        streak: 0,
        xp: 0
    )

    init(
        appLanguage: AppLanguage,
        currentLevel: LearningLevel,
        score0To160: Int,
        dailyGoal: Int,
        voiceID: SpeechVoiceOption? = .american,
        selectedTopics: [String],
        unknownWordIDs: [String],
        savedWordIDs: [String],
        favoriteWordIDs: [String],
        completedTodayIDs: [String],
        wordProgress: [String: WordMemory],
        dailyProgress: [String: DailyProgress],
        practiceHistory: [PracticeRecord],
        streak: Int,
        xp: Int
    ) {
        self.appLanguage = appLanguage
        self.currentLevel = currentLevel
        self.score0To160 = max(0, min(score0To160, 160))
        self.dailyGoal = dailyGoal
        self.voiceID = voiceID
        self.selectedTopics = selectedTopics
        self.unknownWordIDs = unknownWordIDs
        self.savedWordIDs = savedWordIDs
        self.favoriteWordIDs = favoriteWordIDs
        self.completedTodayIDs = completedTodayIDs
        self.wordProgress = wordProgress
        self.dailyProgress = dailyProgress
        self.practiceHistory = practiceHistory
        self.lastStudyDateKey = Self.todayKey()
        self.streak = streak
        self.xp = xp
        prepareForToday()
    }

    private enum CodingKeys: String, CodingKey {
        case appLanguage
        case level
        case currentLevel
        case score0To160
        case dailyGoal
        case voiceID
        case selectedTopics
        case unknownWordIDs
        case savedWordIDs
        case favoriteWordIDs
        case completedTodayIDs
        case wordProgress
        case dailyProgress
        case practiceHistory
        case lastStudyDateKey
        case streak
        case xp
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .russian
        let migratedLevel = try container.decodeIfPresent(LearningLevel.self, forKey: .currentLevel)
            ?? container.decodeIfPresent(LearningLevel.self, forKey: .level)
            ?? .a2
        currentLevel = migratedLevel
        score0To160 = try container.decodeIfPresent(Int.self, forKey: .score0To160) ?? migratedLevel.scoreStart
        dailyGoal = try container.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 7
        voiceID = try container.decodeIfPresent(SpeechVoiceOption.self, forKey: .voiceID) ?? .american
        selectedTopics = try container.decodeIfPresent([String].self, forKey: .selectedTopics) ?? ["Everyday", "Work", "Study"]
        unknownWordIDs = try container.decodeIfPresent([String].self, forKey: .unknownWordIDs) ?? []
        savedWordIDs = try container.decodeIfPresent([String].self, forKey: .savedWordIDs) ?? []
        favoriteWordIDs = try container.decodeIfPresent([String].self, forKey: .favoriteWordIDs) ?? []
        completedTodayIDs = try container.decodeIfPresent([String].self, forKey: .completedTodayIDs) ?? []
        wordProgress = try container.decodeIfPresent([String: WordMemory].self, forKey: .wordProgress) ?? [:]
        dailyProgress = try container.decodeIfPresent([String: DailyProgress].self, forKey: .dailyProgress) ?? [:]
        practiceHistory = try container.decodeIfPresent([PracticeRecord].self, forKey: .practiceHistory) ?? []
        lastStudyDateKey = try container.decodeIfPresent(String.self, forKey: .lastStudyDateKey) ?? Self.todayKey()
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        xp = try container.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        prepareForToday()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appLanguage, forKey: .appLanguage)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(score0To160, forKey: .score0To160)
        try container.encode(dailyGoal, forKey: .dailyGoal)
        try container.encodeIfPresent(voiceID, forKey: .voiceID)
        try container.encode(selectedTopics, forKey: .selectedTopics)
        try container.encode(unknownWordIDs, forKey: .unknownWordIDs)
        try container.encode(savedWordIDs, forKey: .savedWordIDs)
        try container.encode(favoriteWordIDs, forKey: .favoriteWordIDs)
        try container.encode(completedTodayIDs, forKey: .completedTodayIDs)
        try container.encode(wordProgress, forKey: .wordProgress)
        try container.encode(dailyProgress, forKey: .dailyProgress)
        try container.encode(practiceHistory, forKey: .practiceHistory)
        try container.encode(lastStudyDateKey, forKey: .lastStudyDateKey)
        try container.encode(streak, forKey: .streak)
        try container.encode(xp, forKey: .xp)
    }

    var dailyWords: [WordEntry] {
        WordBank.dailyWords(for: self)
    }

    var selectedSpeechVoice: SpeechVoiceOption {
        voiceID ?? .american
    }

    var completedTodayCount: Int {
        dailyProgress[Self.todayKey()]?.completedWordIDs.count ?? completedTodayIDs.count
    }

    var dueWordsCount: Int {
        WordBank.all.filter { wordProgress[$0.id]?.isDue() == true }.count
    }

    var weakWordIDs: [String] {
        wordProgress
            .filter { _, memory in memory.wrongCount > 0 || (memory.totalAttempts > 0 && memory.mastery < 45) }
            .sorted { lhs, rhs in lhs.value.mastery < rhs.value.mastery }
            .map(\.key)
    }

    var overallAccuracy: Double {
        let correct = dailyProgress.values.map(\.correct).reduce(0, +)
        let wrong = dailyProgress.values.map(\.wrong).reduce(0, +)
        guard correct + wrong > 0 else { return 0 }
        return Double(correct) / Double(correct + wrong)
    }

    mutating func prepareForToday() {
        let today = Self.todayKey()
        if lastStudyDateKey != today {
            completedTodayIDs = []
            lastStudyDateKey = today
        }

        if dailyProgress[today] == nil {
            dailyProgress[today] = .empty(for: today)
        }
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
        prepareForToday()
        completedTodayIDs.appendUnique(id)
        dailyProgress[Self.todayKey(), default: .empty(for: Self.todayKey())].completedWordIDs.appendUnique(id)
    }

    mutating func recordPractice(word: WordEntry, mode: PracticeMode, isCorrect: Bool) -> Int {
        MemoryEngine.record(word: word, mode: mode, isCorrect: isCorrect, profile: &self)
    }

    static func todayKey(date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

enum MemoryEngine {
    static func record(word: WordEntry, mode: PracticeMode, isCorrect: Bool, profile: inout AtlasProfile) -> Int {
        profile.prepareForToday()

        var memory = profile.wordProgress[word.id] ?? .fresh
        let now = Date()
        let xp = isCorrect ? mode.xpReward : 0

        if isCorrect {
            memory.correctCount += 1
            memory.streak += 1
            memory.mastery = min(100, memory.mastery + 16 + min(memory.streak, 4) * 3)
            memory.dueAt = Calendar.current.date(byAdding: .day, value: intervalDays(for: memory), to: now)
            profile.markCompleted(word.id)
            if memory.mastery >= 45 {
                profile.unknownWordIDs.removeAll { $0 == word.id }
            }
            profile.score0To160 = min(160, profile.score0To160 + scoreDelta(for: word, current: profile.currentLevel))
        } else {
            memory.wrongCount += 1
            memory.streak = 0
            memory.mastery = max(0, memory.mastery - 18)
            memory.dueAt = Calendar.current.date(byAdding: .hour, value: 18, to: now)
            profile.addUnknown(word.id)
            profile.score0To160 = max(0, profile.score0To160 - 1)
        }

        memory.lastPracticedAt = now
        profile.wordProgress[word.id] = memory
        profile.currentLevel = LearningLevel.from(score: profile.score0To160)
        profile.xp += xp

        let today = AtlasProfile.todayKey(date: now)
        var daily = profile.dailyProgress[today] ?? .empty(for: today)
        daily.xp += xp
        daily.dueCountAtStart = max(daily.dueCountAtStart, profile.dueWordsCount)
        if isCorrect {
            daily.correct += 1
            daily.completedWordIDs.appendUnique(word.id)
        } else {
            daily.wrong += 1
        }
        profile.dailyProgress[today] = daily

        profile.practiceHistory.insert(
            PracticeRecord(
                id: UUID(),
                date: now,
                wordID: word.id,
                wordEnglish: word.english,
                mode: mode,
                isCorrect: isCorrect,
                xp: xp,
                level: word.level
            ),
            at: 0
        )

        if profile.practiceHistory.count > 500 {
            profile.practiceHistory = Array(profile.practiceHistory.prefix(500))
        }

        if isCorrect && profile.streak == 0 {
            profile.streak = 1
        } else if isCorrect && daily.correct == 1 {
            profile.streak += 1
        }

        return xp
    }

    private static func intervalDays(for memory: WordMemory) -> Int {
        switch memory.mastery {
        case 0..<25: 1
        case 25..<45: 2
        case 45..<65: 4
        case 65..<82: 7
        case 82..<94: 14
        default: 30
        }
    }

    private static func scoreDelta(for word: WordEntry, current: LearningLevel) -> Int {
        if word.level.order > current.order { return 3 }
        if word.level.order == current.order { return 2 }
        return 1
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
    static let topics = ["Everyday", "Work", "Study", "Emotions", "Travel", "Business", "Health", "Tech", "Culture", "Nature"]

    static let all: [WordEntry] = {
        if let loaded = loadBundledWords(), !loaded.isEmpty {
            return loaded
        }

        return fallbackWords()
    }()

    static func topicTitle(_ topic: String, for language: AppLanguage) -> String {
        switch topic {
        case "Everyday": language.text(ru: "Каждый день", en: "Everyday")
        case "Work": language.text(ru: "Работа", en: "Work")
        case "Study": language.text(ru: "Учеба", en: "Study")
        case "Emotions": language.text(ru: "Эмоции", en: "Emotions")
        case "Travel": language.text(ru: "Путешествия", en: "Travel")
        case "Business": language.text(ru: "Бизнес", en: "Business")
        case "Health": language.text(ru: "Здоровье", en: "Health")
        case "Tech": language.text(ru: "Технологии", en: "Tech")
        case "Culture": language.text(ru: "Культура", en: "Culture")
        case "Nature": language.text(ru: "Природа", en: "Nature")
        default: topic
        }
    }

    static func dailyWords(for profile: AtlasProfile) -> [WordEntry] {
        let selectedTopics = Set(profile.selectedTopics)
        let now = Date()

        let due = all.filter { word in
            profile.wordProgress[word.id]?.isDue(on: now) == true
        }

        let unknown = profile.unknownWordIDs.compactMap { id in
            all.first { $0.id == id }
        }
        let currentLevel = all.filter { word in
            word.level.order <= profile.currentLevel.order &&
                (selectedTopics.isEmpty || selectedTopics.contains(word.topic))
        }
        let stretch = all.filter { word in
            word.level == profile.currentLevel.next &&
                (selectedTopics.isEmpty || selectedTopics.contains(word.topic))
        }
        let saved = profile.savedWordIDs.compactMap { id in
            all.first { $0.id == id }
        }

        let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let streams = [
            due.sorted { left, right in
                (profile.wordProgress[left.id]?.mastery ?? 0) < (profile.wordProgress[right.id]?.mastery ?? 0)
            },
            unknown,
            rotated(currentLevel, seed: day + profile.score0To160),
            rotated(stretch, seed: day + 91),
            saved
        ]

        var result: [WordEntry] = []
        for stream in streams {
            for word in stream {
                guard !result.contains(where: { $0.id == word.id }) else { continue }
                result.append(word)
                if result.count == profile.dailyGoal { return result }
            }
        }

        for word in rotated(all, seed: day) {
            guard !result.contains(where: { $0.id == word.id }) else { continue }
            result.append(word)
            if result.count == profile.dailyGoal { break }
        }

        return result
    }

    static func assessmentWords(startingAt level: LearningLevel) -> [WordEntry] {
        let desiredLevels = LearningLevel.allCases
        let primary = all.filter { abs($0.level.order - level.order) <= 1 && isAssessmentReady($0) }
        let broader = desiredLevels.flatMap { level in all.filter { $0.level == level && isAssessmentReady($0) }.prefix(6) }
        return Array((primary + broader).uniquedByID().prefix(30))
    }

    static var assessmentWords: [WordEntry] {
        assessmentWords(startingAt: .a2)
    }

    static func isAssessmentReady(_ word: WordEntry) -> Bool {
        word.hasReadableRussian && word.english.rangeOfCharacter(from: .decimalDigits) == nil
    }

    static func translationChoices(for word: WordEntry) -> [String] {
        let pool = all
            .filter { $0.id != word.id && abs($0.level.order - word.level.order) <= 1 && $0.hasReadableRussian }
            .map(\.russian)
        return choices(correct: word.russian, distractors: pool, seed: seed(for: word.id))
    }

    static func synonymChoices(for word: WordEntry) -> [String] {
        let correct = word.synonyms.first ?? "no exact synonym"
        let pool = all
            .filter { $0.id != word.id && $0.partOfSpeech == word.partOfSpeech }
            .map(\.english)
        return choices(correct: correct, distractors: pool, seed: seed(for: word.english) + 47)
    }

    static func clozeChoices(for word: WordEntry) -> [String] {
        let pool = all
            .filter { $0.id != word.id && $0.level == word.level }
            .map(\.english)
        return choices(correct: word.english, distractors: pool, seed: seed(for: word.id) + 89)
    }

    static func sentenceTiles(for word: WordEntry) -> [String] {
        let tiles = word.sentenceTiles.isEmpty ? word.exampleEN.split(separator: " ").map(String.init) : word.sentenceTiles
        return rotated(tiles, seed: seed(for: word.id) + 19)
    }

    static func sentenceAnswer(for word: WordEntry) -> String {
        (word.sentenceTiles.isEmpty ? word.exampleEN.split(separator: " ").map(String.init) : word.sentenceTiles)
            .joined(separator: " ")
            .trimmingCharacters(in: .punctuationCharacters)
    }

    private static func choices(correct: String, distractors: [String], seed: Int) -> [String] {
        let cleanPool = Array(Set(distractors.filter { !$0.isEmpty && $0 != correct })).sorted()
        var result = Array(rotated(cleanPool, seed: seed).prefix(3))
        let insertIndex = result.isEmpty ? 0 : abs(seed) % (result.count + 1)
        result.insert(correct, at: insertIndex)
        return Array(result.prefix(4))
    }

    private static func loadBundledWords() -> [WordEntry]? {
        guard let url = Bundle.main.url(forResource: "WordBank", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([WordEntry].self, from: data)
        else {
            return nil
        }

        return decoded
    }

    private static func fallbackWords() -> [WordEntry] {
        [
            w("focus", "focus", "фокус", "noun", .a1, "Study", ["attention"]),
            w("goal", "goal", "цель", "noun", .a1, "Everyday", ["aim"]),
            w("habit", "habit", "привычка", "noun", .a1, "Everyday", ["routine"]),
            w("effort", "effort", "усилие", "noun", .a2, "Study", ["work"]),
            w("improve", "improve", "улучшать", "verb", .a2, "Study", ["upgrade"]),
            w("confident", "confident", "уверенный", "adjective", .b1, "Emotions", ["sure"]),
            w("concise", "concise", "краткий", "adjective", .b2, "Work", ["brief"]),
            w("coherent", "coherent", "связный", "adjective", .c1, "Study", ["logical"]),
            w("ubiquitous", "ubiquitous", "повсеместный", "adjective", .c2, "Business", ["everywhere"])
        ]
    }

    private static func w(
        _ id: String,
        _ english: String,
        _ russian: String,
        _ partOfSpeech: String,
        _ level: LearningLevel,
        _ topic: String,
        _ synonyms: [String]
    ) -> WordEntry {
        WordEntry(
            id: id,
            english: english,
            russian: russian,
            partOfSpeech: partOfSpeech,
            ipa: "/\(english)/",
            definitionEN: "A useful \(partOfSpeech) for \(topic.lowercased()) communication.",
            definitionRU: "Полезное слово для темы \(topicTitle(topic, for: .russian).lowercased()).",
            exampleEN: "I can use \(english) in a clear sentence.",
            exampleRU: "Я могу использовать \(english) в понятном предложении.",
            level: level,
            topic: topic,
            synonyms: synonyms,
            sentenceTiles: ["I", "can", "use", english, "today"],
            clozeSentence: "I can use ____ today."
        )
    }

    static func rotated<T>(_ items: [T], seed: Int) -> [T] {
        guard !items.isEmpty else { return [] }
        let offset = abs(seed) % items.count
        return Array(items[offset..<items.count]) + Array(items[0..<offset])
    }

    static func seed(for value: String) -> Int {
        value.unicodeScalars.reduce(0) { partialResult, scalar in
            (partialResult + Int(scalar.value)) % 10_000
        }
    }
}

extension Array where Element == WordEntry {
    func uniquedByID() -> [WordEntry] {
        var seen = Set<String>()
        var result: [WordEntry] = []

        for word in self where !seen.contains(word.id) {
            seen.insert(word.id)
            result.append(word)
        }

        return result
    }
}
