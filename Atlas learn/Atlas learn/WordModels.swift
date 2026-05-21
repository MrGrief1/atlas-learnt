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

    var atlasScoreRange: ClosedRange<Int> {
        switch self {
        case .a1: 0...99
        case .a2: 100...199
        case .b1: 200...299
        case .b2: 300...399
        case .c1: 400...499
        case .c2: 500...600
        }
    }

    var atlasScoreStart: Int { atlasScoreRange.lowerBound }

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

    static func from(atlasScore: Int) -> LearningLevel {
        let clamped = max(0, min(atlasScore, 600))
        return allCases.first { $0.atlasScoreRange.contains(clamped) } ?? .c2
    }

    static func atlasScore(fromLegacyScore score: Int) -> Int {
        Int((Double(max(0, min(score, 160))) / 160.0 * 600.0).rounded())
    }

    static func legacyScore(fromAtlasScore atlasScore: Int) -> Int {
        Int((Double(max(0, min(atlasScore, 600))) / 600.0 * 160.0).rounded())
    }

    static func atlasScore(fromTheta theta: Double) -> Int {
        let normalized = (min(max(theta, -3.0), 3.0) + 3.0) / 6.0
        return min(600, max(0, Int((normalized * 600).rounded())))
    }

    static func sublevel(forAtlasScore atlasScore: Int) -> LearningSublevel {
        let level = from(atlasScore: atlasScore)
        let position = max(0, min(99, atlasScore - level.atlasScoreRange.lowerBound))
        let index = min(4, max(1, (position / 25) + 1))
        return LearningSublevel(level: level, index: index)
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
    case wordReveal
    case listenChoice
    case translateChoice
    case synonymMatch
    case sentenceBuilder
    case sentenceCompose
    case clozeChoice
    case meaningChoice
    case ruToEnglishTiles
    case listenTiles
    case clozeWord
    case wordOrder
    case speechRepeat
    case senseSnap
    case contextCloze
    case collocationLock
    case dialogueChoice
    case wordBuilder
    case audioCatch
    case dictationSprint
    case tileTranslation
    case grammarBridge
    case mistakeClinic
    case memoryPairs
    case speedReview
    case speakingEcho
    case bossChallenge
    case sentenceOrder

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wordReveal: "sparkle.magnifyingglass"
        case .listenChoice: "speaker.wave.2"
        case .translateChoice: "text.bubble"
        case .synonymMatch: "link"
        case .sentenceBuilder: "square.grid.3x1.below.line.grid.1x2"
        case .sentenceCompose: "pencil.and.scribble"
        case .clozeChoice: "text.cursor"
        case .meaningChoice: "checklist"
        case .ruToEnglishTiles: "translate"
        case .listenTiles: "waveform"
        case .clozeWord: "text.cursor"
        case .wordOrder: "text.line.first.and.arrowtriangle.forward"
        case .speechRepeat: "mic.fill"
        case .senseSnap: "scope"
        case .contextCloze: "text.cursor"
        case .collocationLock: "lock.doc"
        case .dialogueChoice: "bubble.left.and.bubble.right"
        case .wordBuilder: "hammer"
        case .audioCatch: "ear"
        case .dictationSprint: "keyboard"
        case .tileTranslation: "square.grid.3x3"
        case .grammarBridge: "point.3.connected.trianglepath.dotted"
        case .mistakeClinic: "cross.case"
        case .memoryPairs: "rectangle.on.rectangle"
        case .speedReview: "timer"
        case .speakingEcho: "mic.circle"
        case .bossChallenge: "crown"
        case .sentenceOrder: "text.line.first.and.arrowtriangle.forward"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .wordReveal:
            language.text(ru: "Открытие", en: "Reveal")
        case .listenChoice:
            language.text(ru: "На слух", en: "Listen")
        case .translateChoice:
            language.text(ru: "Перевод", en: "Translation")
        case .synonymMatch:
            language.text(ru: "Синоним", en: "Synonym")
        case .sentenceBuilder:
            language.text(ru: "Собери фразу", en: "Build sentence")
        case .sentenceCompose:
            language.text(ru: "Своя фраза", en: "Own sentence")
        case .clozeChoice:
            language.text(ru: "Пропуск", en: "Fill the blank")
        case .meaningChoice:
            language.text(ru: "Смысл", en: "Meaning")
        case .ruToEnglishTiles:
            language.text(ru: "RU → EN", en: "RU → EN")
        case .listenTiles:
            language.text(ru: "На слух", en: "Listening")
        case .clozeWord:
            language.text(ru: "Пропуск", en: "Blank")
        case .wordOrder:
            language.text(ru: "Порядок слов", en: "Word order")
        case .speechRepeat:
            language.text(ru: "Произношение", en: "Speaking")
        case .senseSnap:
            language.text(ru: "Смысл в контексте", en: "Sense Snap")
        case .contextCloze:
            language.text(ru: "Контекст", en: "Context Cloze")
        case .collocationLock:
            language.text(ru: "Сочетания", en: "Collocation Lock")
        case .dialogueChoice:
            language.text(ru: "Диалог", en: "Dialogue Choice")
        case .wordBuilder:
            language.text(ru: "Собери слово", en: "Word Builder")
        case .audioCatch:
            language.text(ru: "Поймай звук", en: "Audio Catch")
        case .dictationSprint:
            language.text(ru: "Диктант", en: "Dictation Sprint")
        case .tileTranslation:
            language.text(ru: "Плитки 2.0", en: "Tile Translation")
        case .grammarBridge:
            language.text(ru: "Грамматика", en: "Grammar Bridge")
        case .mistakeClinic:
            language.text(ru: "Клиника ошибок", en: "Mistake Clinic")
        case .memoryPairs:
            language.text(ru: "Пары памяти", en: "Memory Pairs")
        case .speedReview:
            language.text(ru: "Скорость", en: "Speed Review")
        case .speakingEcho:
            language.text(ru: "Эхо", en: "Speaking Echo")
        case .bossChallenge:
            language.text(ru: "Босс", en: "Boss Challenge")
        case .sentenceOrder:
            language.text(ru: "Порядок", en: "Sentence Order")
        }
    }

    func subtitle(for language: AppLanguage) -> String {
        switch self {
        case .wordReveal:
            language.text(ru: "Разбери значение и пример", en: "Study meaning and example")
        case .listenChoice:
            language.text(ru: "Узнай слово по произношению", en: "Recognize the spoken word")
        case .translateChoice:
            language.text(ru: "Выбери русский перевод", en: "Choose the Russian meaning")
        case .synonymMatch:
            language.text(ru: "Найди близкое английское слово", en: "Find the closest English word")
        case .sentenceBuilder:
            language.text(ru: "Расставь плитки по порядку", en: "Put the tiles in order")
        case .sentenceCompose:
            language.text(ru: "Напиши предложение со словом", en: "Write a sentence with the word")
        case .clozeChoice:
            language.text(ru: "Вставь слово в контекст", en: "Use the word in context")
        case .meaningChoice:
            language.text(ru: "Выбери точное значение слова", en: "Choose the exact meaning")
        case .ruToEnglishTiles:
            language.text(ru: "Собери английскую фразу по русской", en: "Build English from the Russian cue")
        case .listenTiles:
            language.text(ru: "Слушай фразу и собери ее", en: "Listen and assemble the phrase")
        case .clozeWord:
            language.text(ru: "Вставь слово в пропуск", en: "Put the word into the blank")
        case .wordOrder:
            language.text(ru: "Поставь слова в естественном порядке", en: "Put words in a natural order")
        case .speechRepeat:
            language.text(ru: "Повтори слово или короткую фразу", en: "Repeat the word or short phrase")
        case .senseSnap:
            language.text(ru: "Пойми значение в живом предложении", en: "Understand meaning inside context")
        case .contextCloze:
            language.text(ru: "Вставь слово туда, где оно звучит естественно", en: "Fit the word into a natural context")
        case .collocationLock:
            language.text(ru: "Выбери естественное английское сочетание", en: "Choose the natural English phrase")
        case .dialogueChoice:
            language.text(ru: "Подбери уместную реплику", en: "Pick the fitting reply")
        case .wordBuilder:
            language.text(ru: "Собери слово из частей", en: "Build the word from pieces")
        case .audioCatch:
            language.text(ru: "Услышь целевое слово", en: "Catch the target word by ear")
        case .dictationSprint:
            language.text(ru: "Впиши услышанное слово", en: "Type the word you hear")
        case .tileTranslation:
            language.text(ru: "Собери фразу с лишними плитками", en: "Build the sentence with extra tiles")
        case .grammarBridge:
            language.text(ru: "Проверь грамматику через слово", en: "Check grammar through the word")
        case .mistakeClinic:
            language.text(ru: "Исправь недавнюю ошибку в новом формате", en: "Fix a recent mistake in a new format")
        case .memoryPairs:
            language.text(ru: "Соедини слово, смысл и контекст", en: "Match word, meaning, and context")
        case .speedReview:
            language.text(ru: "Быстрая проверка слабых слов", en: "Fast check for weak words")
        case .speakingEcho:
            language.text(ru: "Повтори мягко, без идеального акцента", en: "Repeat softly, no perfect accent required")
        case .bossChallenge:
            language.text(ru: "Смешанная проверка без подсказок", en: "Mixed check without hints")
        case .sentenceOrder:
            language.text(ru: "Поставь слова в естественный порядок", en: "Put words in a natural order")
        }
    }

    var xpReward: Int {
        switch self {
        case .wordReveal: 5
        case .listenChoice: 10
        case .translateChoice: 10
        case .synonymMatch: 12
        case .sentenceBuilder: 15
        case .sentenceCompose: 18
        case .clozeChoice: 14
        case .meaningChoice: 8
        case .ruToEnglishTiles: 12
        case .listenTiles: 12
        case .clozeWord: 10
        case .wordOrder: 12
        case .speechRepeat: 10
        case .senseSnap: 8
        case .contextCloze: 12
        case .collocationLock: 12
        case .dialogueChoice: 8
        case .wordBuilder: 10
        case .audioCatch: 10
        case .dictationSprint: 12
        case .tileTranslation: 12
        case .grammarBridge: 12
        case .mistakeClinic: 10
        case .memoryPairs: 8
        case .speedReview: 5
        case .speakingEcho: 15
        case .bossChallenge: 20
        case .sentenceOrder: 12
        }
    }
}

enum PracticeStep: String, CaseIterable, Codable, Identifiable {
    case meaningChoice
    case ruToEnglishTiles
    case listenTiles
    case clozeWord
    case wordOrder
    case speechRepeat

    var id: String { rawValue }

    var mode: PracticeMode {
        switch self {
        case .meaningChoice: .meaningChoice
        case .ruToEnglishTiles: .ruToEnglishTiles
        case .listenTiles: .listenTiles
        case .clozeWord: .clozeWord
        case .wordOrder: .wordOrder
        case .speechRepeat: .speechRepeat
        }
    }

    var icon: String { mode.icon }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .meaningChoice:
            language.text(ru: "Выбери смысл", en: "Choose meaning")
        case .ruToEnglishTiles:
            language.text(ru: "Собери перевод", en: "Build translation")
        case .listenTiles:
            language.text(ru: "Собери на слух", en: "Build by ear")
        case .clozeWord:
            language.text(ru: "Вставь слово", en: "Fill the word")
        case .wordOrder:
            language.text(ru: "Порядок слов", en: "Word order")
        case .speechRepeat:
            language.text(ru: "Повтори вслух", en: "Repeat aloud")
        }
    }

    func subtitle(for language: AppLanguage) -> String {
        switch self {
        case .meaningChoice:
            language.text(ru: "Слово сразу включается в проверку смысла.", en: "The word goes straight into meaning practice.")
        case .ruToEnglishTiles:
            language.text(ru: "Дана русская фраза, собери английскую.", en: "Use the Russian cue to build the English sentence.")
        case .listenTiles:
            language.text(ru: "Слушай английскую фразу и собери ее из плиток.", en: "Listen to the English sentence and assemble it.")
        case .clozeWord:
            language.text(ru: "Найди место слова внутри контекста.", en: "Place the target word inside context.")
        case .wordOrder:
            language.text(ru: "Собери естественный порядок слов.", en: "Assemble natural word order.")
        case .speechRepeat:
            language.text(ru: "Скажи слово или короткую фразу в микрофон.", en: "Say the word or a short phrase into the mic.")
        }
    }

    func actionTitle(for language: AppLanguage) -> String {
        switch self {
        case .meaningChoice:
            language.text(ru: "Выбери вариант", en: "Choose an option")
        case .ruToEnglishTiles, .listenTiles, .clozeWord, .wordOrder:
            language.text(ru: "Проверить", en: "Check")
        case .speechRepeat:
            language.text(ru: "Проверить речь", en: "Check speech")
        }
    }
}

struct PracticeStageResult: Codable, Equatable, Identifiable {
    let id: UUID
    let step: PracticeStep
    let mode: PracticeMode
    let wordID: String
    let isCorrect: Bool
    let wasSkipped: Bool
    let xp: Int
    let createdAt: Date

    init(
        id: UUID = UUID(),
        step: PracticeStep,
        mode: PracticeMode? = nil,
        wordID: String,
        isCorrect: Bool,
        wasSkipped: Bool = false,
        xp: Int,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.step = step
        self.mode = mode ?? step.mode
        self.wordID = wordID
        self.isCorrect = isCorrect
        self.wasSkipped = wasSkipped
        self.xp = xp
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case step
        case mode
        case wordID
        case isCorrect
        case wasSkipped
        case xp
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        step = try container.decode(PracticeStep.self, forKey: .step)
        mode = try container.decodeIfPresent(PracticeMode.self, forKey: .mode) ?? step.mode
        wordID = try container.decode(String.self, forKey: .wordID)
        isCorrect = try container.decode(Bool.self, forKey: .isCorrect)
        wasSkipped = try container.decodeIfPresent(Bool.self, forKey: .wasSkipped) ?? false
        xp = try container.decode(Int.self, forKey: .xp)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
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
    let lemma: String
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
    let frequencyRank: Int?
    let subtopics: [String]
    let register: String?
    let synonyms: [String]
    let senses: [WordSense]
    let sentenceTiles: [String]
    let clozeSentence: String
    let hints: [String]
    let collocations: [String]
    let phrasalForms: [String]
    let wordFamily: [String]
    let confusionGroup: [String]
    let grammarPatterns: [String]
    let examples: [WordExample]
    let safetyTags: [String]
    let extraExamplesEN: [String]
    let extraExamplesRU: [String]
    let composePromptEN: String
    let composePromptRU: String
    let acceptedAnswers: [String]

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

    func composePrompt(for language: AppLanguage) -> String {
        language.text(ru: composePromptRU, en: composePromptEN)
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case lemma
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
        case frequencyRank
        case subtopics
        case register
        case synonyms
        case senses
        case sentenceTiles
        case clozeSentence
        case hints
        case collocations
        case phrasalForms
        case wordFamily
        case confusionGroup
        case grammarPatterns
        case examples
        case safetyTags
        case extraExamplesEN
        case extraExamplesRU
        case composePromptEN
        case composePromptRU
        case acceptedAnswers
    }

    init(
        id: String,
        lemma: String? = nil,
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
        frequencyRank: Int? = nil,
        subtopics: [String] = [],
        register: String? = nil,
        synonyms: [String],
        senses: [WordSense] = [],
        sentenceTiles: [String],
        clozeSentence: String,
        hints: [String] = [],
        collocations: [String] = [],
        phrasalForms: [String] = [],
        wordFamily: [String] = [],
        confusionGroup: [String] = [],
        grammarPatterns: [String] = [],
        examples: [WordExample] = [],
        safetyTags: [String] = [],
        extraExamplesEN: [String] = [],
        extraExamplesRU: [String] = [],
        composePromptEN: String = "",
        composePromptRU: String = "",
        acceptedAnswers: [String] = []
    ) {
        self.id = id
        self.lemma = lemma ?? english.lowercased()
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
        self.frequencyRank = frequencyRank
        self.subtopics = subtopics
        self.register = register
        self.synonyms = synonyms
        self.senses = senses
        self.sentenceTiles = sentenceTiles
        self.clozeSentence = clozeSentence
        self.hints = hints
        self.collocations = collocations
        self.phrasalForms = phrasalForms
        self.wordFamily = wordFamily
        self.confusionGroup = confusionGroup
        self.grammarPatterns = grammarPatterns
        self.examples = examples.isEmpty
            ? [WordExample(english: exampleEN, russian: exampleRU, level: level, topic: topic, source: "local")]
            : examples
        self.safetyTags = safetyTags
        self.extraExamplesEN = extraExamplesEN
        self.extraExamplesRU = extraExamplesRU
        self.composePromptEN = composePromptEN.isEmpty ? "Write a short sentence with \(english)." : composePromptEN
        self.composePromptRU = composePromptRU.isEmpty ? "Напиши короткое предложение со словом \(english)." : composePromptRU
        self.acceptedAnswers = acceptedAnswers
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        english = try container.decode(String.self, forKey: .english)
        lemma = try container.decodeIfPresent(String.self, forKey: .lemma) ?? english.lowercased()
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
        frequencyRank = try container.decodeIfPresent(Int.self, forKey: .frequencyRank)
        subtopics = try container.decodeIfPresent([String].self, forKey: .subtopics) ?? []
        register = try container.decodeIfPresent(String.self, forKey: .register)
        synonyms = try container.decodeIfPresent([String].self, forKey: .synonyms) ?? []
        senses = try container.decodeIfPresent([WordSense].self, forKey: .senses) ?? []
        sentenceTiles = try container.decodeIfPresent([String].self, forKey: .sentenceTiles) ?? exampleEN.split(separator: " ").map(String.init)
        clozeSentence = try container.decodeIfPresent(String.self, forKey: .clozeSentence) ?? exampleEN.replacingOccurrences(of: english, with: "____")
        hints = try container.decodeIfPresent([String].self, forKey: .hints) ?? []
        collocations = try container.decodeIfPresent([String].self, forKey: .collocations) ?? []
        phrasalForms = try container.decodeIfPresent([String].self, forKey: .phrasalForms) ?? []
        wordFamily = try container.decodeIfPresent([String].self, forKey: .wordFamily) ?? []
        confusionGroup = try container.decodeIfPresent([String].self, forKey: .confusionGroup) ?? []
        grammarPatterns = try container.decodeIfPresent([String].self, forKey: .grammarPatterns) ?? []
        examples = try container.decodeIfPresent([WordExample].self, forKey: .examples)
            ?? [WordExample(english: exampleEN, russian: exampleRU, level: level, topic: topic, source: "local")]
        safetyTags = try container.decodeIfPresent([String].self, forKey: .safetyTags) ?? []
        extraExamplesEN = try container.decodeIfPresent([String].self, forKey: .extraExamplesEN) ?? []
        extraExamplesRU = try container.decodeIfPresent([String].self, forKey: .extraExamplesRU) ?? []
        composePromptEN = try container.decodeIfPresent(String.self, forKey: .composePromptEN) ?? "Write a short sentence with \(english)."
        composePromptRU = try container.decodeIfPresent(String.self, forKey: .composePromptRU) ?? "Напиши короткое предложение со словом \(english)."
        acceptedAnswers = try container.decodeIfPresent([String].self, forKey: .acceptedAnswers) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(lemma, forKey: .lemma)
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
        try container.encodeIfPresent(frequencyRank, forKey: .frequencyRank)
        try container.encode(subtopics, forKey: .subtopics)
        try container.encodeIfPresent(register, forKey: .register)
        try container.encode(synonyms, forKey: .synonyms)
        try container.encode(senses, forKey: .senses)
        try container.encode(sentenceTiles, forKey: .sentenceTiles)
        try container.encode(clozeSentence, forKey: .clozeSentence)
        try container.encode(hints, forKey: .hints)
        try container.encode(collocations, forKey: .collocations)
        try container.encode(phrasalForms, forKey: .phrasalForms)
        try container.encode(wordFamily, forKey: .wordFamily)
        try container.encode(confusionGroup, forKey: .confusionGroup)
        try container.encode(grammarPatterns, forKey: .grammarPatterns)
        try container.encode(examples, forKey: .examples)
        try container.encode(safetyTags, forKey: .safetyTags)
        try container.encode(extraExamplesEN, forKey: .extraExamplesEN)
        try container.encode(extraExamplesRU, forKey: .extraExamplesRU)
        try container.encode(composePromptEN, forKey: .composePromptEN)
        try container.encode(composePromptRU, forKey: .composePromptRU)
        try container.encode(acceptedAnswers, forKey: .acceptedAnswers)
    }
}

struct PracticeQuestion: Codable, Equatable, Identifiable {
    let id: UUID
    let wordID: WordEntry.ID
    let step: PracticeStep
    let isRepair: Bool
    let task: GeneratedGameTask?

    init(
        id: UUID = UUID(),
        wordID: WordEntry.ID,
        step: PracticeStep,
        isRepair: Bool = false,
        task: GeneratedGameTask? = nil
    ) {
        self.id = id
        self.wordID = wordID
        self.step = step
        self.isRepair = isRepair
        self.task = task
    }

    nonisolated init(task: GeneratedGameTask) {
        self.id = task.id
        self.wordID = task.wordID
        self.step = task.closestStep
        self.isRepair = task.isRepair
        self.task = task
    }
}

struct PracticeSession: Codable, Equatable, Identifiable {
    let id: UUID
    var questions: [PracticeQuestion]
    var currentQuestionIndex: Int
    var hearts: Int
    var xp: Int
    var results: [PracticeStageResult]
    var repairCounts: [String: Int]

    init(
        id: UUID = UUID(),
        questions: [PracticeQuestion],
        hearts: Int = 3
    ) {
        self.id = id
        self.questions = questions
        self.currentQuestionIndex = 0
        self.hearts = hearts
        self.xp = 0
        self.results = []
        self.repairCounts = [:]
    }

    init(
        id: UUID = UUID(),
        tasks: [GeneratedGameTask],
        hearts: Int = 3
    ) {
        self.id = id
        self.questions = tasks.map(PracticeQuestion.init(task:))
        self.currentQuestionIndex = 0
        self.hearts = hearts
        self.xp = 0
        self.results = []
        self.repairCounts = [:]
    }

    init(
        id: UUID = UUID(),
        words: [WordEntry],
        startWordID: WordEntry.ID?,
        steps: [PracticeStep] = PracticeStep.allCases,
        hearts: Int = 3
    ) {
        let uniqueWords = words.uniquedByID()
        var questions: [PracticeQuestion] = []

        for word in uniqueWords {
            for step in steps {
                questions.append(PracticeQuestion(wordID: word.id, step: step))
            }
        }

        if let startWordID,
           let startIndex = questions.firstIndex(where: { $0.wordID == startWordID }) {
            let prefix = questions[..<startIndex]
            questions = Array(questions[startIndex...]) + Array(prefix)
        }

        self.id = id
        self.questions = questions
        self.currentQuestionIndex = 0
        self.hearts = hearts
        self.xp = 0
        self.results = []
        self.repairCounts = [:]
    }

    var currentQuestion: PracticeQuestion? {
        guard questions.indices.contains(currentQuestionIndex) else { return nil }
        return questions[currentQuestionIndex]
    }

    var currentTask: GeneratedGameTask? {
        currentQuestion?.task
    }

    var currentWordID: WordEntry.ID? {
        currentQuestion?.wordID
    }

    var currentStep: PracticeStep {
        currentQuestion?.step ?? .meaningChoice
    }

    var currentMode: PracticeMode {
        currentTask?.mode ?? currentStep.mode
    }

    var wordIDs: [WordEntry.ID] {
        var seen = Set<WordEntry.ID>()
        var result: [WordEntry.ID] = []

        for question in questions where !seen.contains(question.wordID) {
            seen.insert(question.wordID)
            result.append(question.wordID)
        }

        return result
    }

    var currentWordIndex: Int {
        guard let currentWordID else { return 0 }
        return wordIDs.firstIndex(of: currentWordID) ?? 0
    }

    var wordCount: Int {
        wordIDs.count
    }

    var questionPosition: Int {
        min(currentQuestionIndex + 1, max(questions.count, 1))
    }

    var questionCount: Int {
        questions.count
    }

    var currentWordSteps: [PracticeStep] {
        guard let currentWordID else { return [] }

        var seen = Set<PracticeStep>()
        var result: [PracticeStep] = []

        for question in questions where question.wordID == currentWordID && !question.isRepair {
            guard !seen.contains(question.step) else { continue }
            seen.insert(question.step)
            result.append(question.step)
        }

        if !seen.contains(currentStep) {
            result.append(currentStep)
        }

        return result
    }

    var currentWordModes: [PracticeMode] {
        guard let currentWordID else { return [] }

        var seen = Set<PracticeMode>()
        var result: [PracticeMode] = []

        for question in questions where question.wordID == currentWordID && !question.isRepair {
            let mode = question.task?.mode ?? question.step.mode
            guard !seen.contains(mode) else { continue }
            seen.insert(mode)
            result.append(mode)
        }

        if !seen.contains(currentMode) {
            result.append(currentMode)
        }

        return result
    }

    var isOnLastQuestion: Bool {
        currentQuestionIndex >= questions.count - 1
    }

    var progress: Double {
        guard !questions.isEmpty else { return 0 }
        return Double(currentQuestionIndex) / Double(questions.count)
    }

    var correctCount: Int {
        results.filter { $0.isCorrect && !$0.wasSkipped }.count
    }

    var wrongCount: Int {
        results.filter { !$0.isCorrect && !$0.wasSkipped }.count
    }

    var scoredCount: Int {
        results.filter { !$0.wasSkipped }.count
    }

    var practicedWordCount: Int {
        Set(results.map(\.wordID)).count
    }

    @discardableResult
    mutating func record(step: PracticeStep, mode: PracticeMode? = nil, wordID: WordEntry.ID, isCorrect: Bool, xp: Int, wasSkipped: Bool = false) -> Bool {
        results.append(PracticeStageResult(step: step, mode: mode, wordID: wordID, isCorrect: isCorrect, wasSkipped: wasSkipped, xp: xp))
        self.xp += xp

        if !isCorrect && !wasSkipped {
            hearts = max(0, hearts - 1)
            return scheduleRepairIfNeeded(step: step, wordID: wordID)
        }

        return false
    }

    mutating func advanceQuestion() {
        currentQuestionIndex = min(currentQuestionIndex + 1, max(questions.count - 1, 0))
    }

    private mutating func scheduleRepairIfNeeded(step: PracticeStep, wordID: WordEntry.ID) -> Bool {
        let key = "\(wordID)|\(step.rawValue)"
        let count = repairCounts[key, default: 0]

        guard count < 2 else { return false }

        repairCounts[key] = count + 1

        let repairQuestion: PracticeQuestion
        if let task = currentQuestion?.task {
            repairQuestion = PracticeQuestion(task: task.repairVariant())
        } else {
            repairQuestion = PracticeQuestion(wordID: wordID, step: step, isRepair: true)
        }
        let insertIndex = min(currentQuestionIndex + 3, questions.count)
        questions.insert(repairQuestion, at: insertIndex)
        return true
    }
}

enum WordSortOption: String, CaseIterable, Identifiable {
    case smart
    case alphabetic
    case level
    case masteryLow
    case masteryHigh
    case topic
    case dueFirst
    case newest

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .smart: "sparkles"
        case .alphabetic: "textformat.abc"
        case .level: "flag.checkered"
        case .masteryLow: "arrow.down.forward.circle"
        case .masteryHigh: "arrow.up.forward.circle"
        case .topic: "square.grid.2x2"
        case .dueFirst: "clock.arrow.circlepath"
        case .newest: "plus.circle"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .smart:
            language.text(ru: "Умно", en: "Smart")
        case .alphabetic:
            language.text(ru: "A-Z", en: "A-Z")
        case .level:
            language.text(ru: "Уровень", en: "Level")
        case .masteryLow:
            language.text(ru: "Слабые", en: "Weak")
        case .masteryHigh:
            language.text(ru: "Освоено", en: "Mastered")
        case .topic:
            language.text(ru: "Тема", en: "Topic")
        case .dueFirst:
            language.text(ru: "Повторить", en: "Due")
        case .newest:
            language.text(ru: "Новые", en: "New")
        }
    }
}

struct WordMemory: Codable, Equatable {
    var exposures: Int
    var correctCount: Int
    var wrongCount: Int
    var streak: Int
    var mastery: Int
    var stability: Double
    var difficulty: Double
    var retrievability: Double
    var lastPracticedAt: Date?
    var dueAt: Date?
    var lastModes: [PracticeMode]
    var errorTypes: [ErrorType: Int]
    var confidenceHistory: [Double]
    var averageResponseTime: Double
    var boredomScore: Double
    var personalRelevance: Double

    static let fresh = WordMemory(
        exposures: 0,
        correctCount: 0,
        wrongCount: 0,
        streak: 0,
        mastery: 0,
        stability: 1,
        difficulty: 0.45,
        retrievability: 0,
        lastPracticedAt: nil,
        dueAt: nil,
        lastModes: [],
        errorTypes: [:],
        confidenceHistory: [],
        averageResponseTime: 0,
        boredomScore: 0,
        personalRelevance: 0
    )

    init(
        exposures: Int = 0,
        correctCount: Int,
        wrongCount: Int,
        streak: Int,
        mastery: Int,
        stability: Double = 1,
        difficulty: Double = 0.45,
        retrievability: Double = 0,
        lastPracticedAt: Date?,
        dueAt: Date?,
        lastModes: [PracticeMode] = [],
        errorTypes: [ErrorType: Int] = [:],
        confidenceHistory: [Double] = [],
        averageResponseTime: Double = 0,
        boredomScore: Double = 0,
        personalRelevance: Double = 0
    ) {
        self.exposures = max(exposures, correctCount + wrongCount)
        self.correctCount = correctCount
        self.wrongCount = wrongCount
        self.streak = streak
        self.mastery = min(max(mastery, 0), 100)
        self.stability = stability
        self.difficulty = min(max(difficulty, 0), 1)
        self.retrievability = min(max(retrievability, 0), 1)
        self.lastPracticedAt = lastPracticedAt
        self.dueAt = dueAt
        self.lastModes = lastModes
        self.errorTypes = errorTypes
        self.confidenceHistory = confidenceHistory
        self.averageResponseTime = averageResponseTime
        self.boredomScore = min(max(boredomScore, 0), 1)
        self.personalRelevance = min(max(personalRelevance, 0), 1)
    }

    private enum CodingKeys: String, CodingKey {
        case exposures
        case correctCount
        case wrongCount
        case streak
        case mastery
        case stability
        case difficulty
        case retrievability
        case lastPracticedAt
        case dueAt
        case lastModes
        case errorTypes
        case confidenceHistory
        case averageResponseTime
        case boredomScore
        case personalRelevance
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        correctCount = try container.decodeIfPresent(Int.self, forKey: .correctCount) ?? 0
        wrongCount = try container.decodeIfPresent(Int.self, forKey: .wrongCount) ?? 0
        exposures = try container.decodeIfPresent(Int.self, forKey: .exposures) ?? correctCount + wrongCount
        streak = try container.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        mastery = try container.decodeIfPresent(Int.self, forKey: .mastery) ?? 0
        stability = try container.decodeIfPresent(Double.self, forKey: .stability) ?? 1
        difficulty = try container.decodeIfPresent(Double.self, forKey: .difficulty) ?? 0.45
        retrievability = try container.decodeIfPresent(Double.self, forKey: .retrievability) ?? 0
        lastPracticedAt = try container.decodeIfPresent(Date.self, forKey: .lastPracticedAt)
        dueAt = try container.decodeIfPresent(Date.self, forKey: .dueAt)
        lastModes = try container.decodeIfPresent([PracticeMode].self, forKey: .lastModes) ?? []
        errorTypes = try container.decodeIfPresent([ErrorType: Int].self, forKey: .errorTypes) ?? [:]
        confidenceHistory = try container.decodeIfPresent([Double].self, forKey: .confidenceHistory) ?? []
        averageResponseTime = try container.decodeIfPresent(Double.self, forKey: .averageResponseTime) ?? 0
        boredomScore = try container.decodeIfPresent(Double.self, forKey: .boredomScore) ?? 0
        personalRelevance = try container.decodeIfPresent(Double.self, forKey: .personalRelevance) ?? 0
    }

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
    var atlasScore: Int
    var placementResult: PlacementResult?
    var skillScores: [PlacementSkill: Int]
    var weakSkills: [PlacementSkill]
    var strongSkills: [PlacementSkill]
    var lastPlacementAt: Date?
    var dailyGoal: Int
    var voiceID: SpeechVoiceOption?
    var selectedTopics: [String]
    var enabledPracticeSteps: [PracticeStep]
    var settings: LearningSettings
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
    var energy: Int
    var unlockedAchievementIDs: [String]
    var currentDailyPack: DailyPack?

    var level: LearningLevel {
        get { currentLevel }
        set {
            currentLevel = newValue
            applyAtlasScore(max(atlasScore, newValue.atlasScoreStart))
        }
    }

    var sublevel: LearningSublevel {
        LearningLevel.sublevel(forAtlasScore: atlasScore)
    }

    var levelTag: String {
        sublevel.tag
    }

    static let `default` = AtlasProfile(
        appLanguage: .russian,
        currentLevel: .a2,
        score0To160: LearningLevel.a2.scoreStart,
        atlasScore: LearningLevel.a2.atlasScoreStart,
        placementResult: nil,
        skillScores: [:],
        weakSkills: [],
        strongSkills: [],
        lastPlacementAt: nil,
        dailyGoal: 7,
        selectedTopics: ["Everyday", "Work", "Study"],
        enabledPracticeSteps: PracticeStep.allCases,
        settings: .default,
        unknownWordIDs: [],
        savedWordIDs: [],
        favoriteWordIDs: [],
        completedTodayIDs: [],
        wordProgress: [:],
        dailyProgress: [:],
        practiceHistory: [],
        streak: 0,
        xp: 0,
        energy: EnergyEngine.maxEnergy,
        unlockedAchievementIDs: [],
        currentDailyPack: nil
    )

    init(
        appLanguage: AppLanguage,
        currentLevel: LearningLevel,
        score0To160: Int,
        atlasScore: Int? = nil,
        placementResult: PlacementResult? = nil,
        skillScores: [PlacementSkill: Int] = [:],
        weakSkills: [PlacementSkill] = [],
        strongSkills: [PlacementSkill] = [],
        lastPlacementAt: Date? = nil,
        dailyGoal: Int,
        voiceID: SpeechVoiceOption? = .american,
        selectedTopics: [String],
        enabledPracticeSteps: [PracticeStep] = PracticeStep.allCases,
        settings: LearningSettings? = nil,
        unknownWordIDs: [String],
        savedWordIDs: [String],
        favoriteWordIDs: [String],
        completedTodayIDs: [String],
        wordProgress: [String: WordMemory],
        dailyProgress: [String: DailyProgress],
        practiceHistory: [PracticeRecord],
        streak: Int,
        xp: Int,
        energy: Int = EnergyEngine.maxEnergy,
        unlockedAchievementIDs: [String] = [],
        currentDailyPack: DailyPack? = nil
    ) {
        self.appLanguage = appLanguage
        self.score0To160 = max(0, min(score0To160, 160))
        self.atlasScore = max(0, min(atlasScore ?? LearningLevel.atlasScore(fromLegacyScore: score0To160), 600))
        self.currentLevel = LearningLevel.from(atlasScore: self.atlasScore)
        if self.currentLevel != currentLevel && atlasScore == nil {
            self.currentLevel = currentLevel
            self.atlasScore = max(self.atlasScore, currentLevel.atlasScoreStart)
        }
        self.placementResult = placementResult
        self.skillScores = skillScores
        self.weakSkills = weakSkills
        self.strongSkills = strongSkills
        self.lastPlacementAt = lastPlacementAt
        self.dailyGoal = dailyGoal
        self.voiceID = voiceID
        self.selectedTopics = selectedTopics
        self.enabledPracticeSteps = enabledPracticeSteps.isEmpty ? PracticeStep.allCases : enabledPracticeSteps
        var resolvedSettings = settings ?? .default
        resolvedSettings.appLanguage = appLanguage
        resolvedSettings.dailyGoal = dailyGoal
        resolvedSettings.selectedTopics = selectedTopics
        resolvedSettings.preferredVoice = voiceID ?? .american
        self.settings = resolvedSettings
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
        self.energy = EnergyEngine.clamped(energy)
        self.unlockedAchievementIDs = unlockedAchievementIDs
        self.currentDailyPack = currentDailyPack
        self.score0To160 = LearningLevel.legacyScore(fromAtlasScore: self.atlasScore)
        prepareForToday()
    }

    private enum CodingKeys: String, CodingKey {
        case appLanguage
        case level
        case currentLevel
        case score0To160
        case atlasScore
        case atlasScore0To600
        case placementResult
        case skillScores
        case weakSkills
        case strongSkills
        case lastPlacementAt
        case dailyGoal
        case voiceID
        case selectedTopics
        case enabledPracticeSteps
        case settings
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
        case energy
        case unlockedAchievementIDs
        case currentDailyPack
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        appLanguage = try container.decodeIfPresent(AppLanguage.self, forKey: .appLanguage) ?? .russian
        let migratedLevel = try container.decodeIfPresent(LearningLevel.self, forKey: .currentLevel)
            ?? container.decodeIfPresent(LearningLevel.self, forKey: .level)
            ?? .a2
        score0To160 = try container.decodeIfPresent(Int.self, forKey: .score0To160) ?? migratedLevel.scoreStart
        atlasScore = try container.decodeIfPresent(Int.self, forKey: .atlasScore)
            ?? container.decodeIfPresent(Int.self, forKey: .atlasScore0To600)
            ?? LearningLevel.atlasScore(fromLegacyScore: score0To160)
        atlasScore = max(0, min(atlasScore, 600))
        currentLevel = LearningLevel.from(atlasScore: atlasScore)
        placementResult = try container.decodeIfPresent(PlacementResult.self, forKey: .placementResult)
        skillScores = try container.decodeIfPresent([PlacementSkill: Int].self, forKey: .skillScores) ?? placementResult?.skillScores ?? [:]
        weakSkills = try container.decodeIfPresent([PlacementSkill].self, forKey: .weakSkills) ?? placementResult?.weakSkills ?? []
        strongSkills = try container.decodeIfPresent([PlacementSkill].self, forKey: .strongSkills) ?? placementResult?.strongSkills ?? []
        lastPlacementAt = try container.decodeIfPresent(Date.self, forKey: .lastPlacementAt) ?? placementResult?.createdAt
        dailyGoal = try container.decodeIfPresent(Int.self, forKey: .dailyGoal) ?? 7
        voiceID = try container.decodeIfPresent(SpeechVoiceOption.self, forKey: .voiceID) ?? .american
        selectedTopics = try container.decodeIfPresent([String].self, forKey: .selectedTopics) ?? ["Everyday", "Work", "Study"]
        enabledPracticeSteps = try container.decodeIfPresent([PracticeStep].self, forKey: .enabledPracticeSteps) ?? PracticeStep.allCases
        if enabledPracticeSteps.isEmpty {
            enabledPracticeSteps = PracticeStep.allCases
        }
        settings = try container.decodeIfPresent(LearningSettings.self, forKey: .settings) ?? .default
        settings.appLanguage = appLanguage
        settings.dailyGoal = dailyGoal
        settings.selectedTopics = selectedTopics
        settings.preferredVoice = voiceID ?? .american
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
        energy = EnergyEngine.clamped(try container.decodeIfPresent(Int.self, forKey: .energy) ?? EnergyEngine.maxEnergy)
        unlockedAchievementIDs = try container.decodeIfPresent([String].self, forKey: .unlockedAchievementIDs) ?? []
        currentDailyPack = try container.decodeIfPresent(DailyPack.self, forKey: .currentDailyPack)
        score0To160 = LearningLevel.legacyScore(fromAtlasScore: atlasScore)
        prepareForToday()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(appLanguage, forKey: .appLanguage)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(score0To160, forKey: .score0To160)
        try container.encode(atlasScore, forKey: .atlasScore)
        try container.encodeIfPresent(placementResult, forKey: .placementResult)
        try container.encode(skillScores, forKey: .skillScores)
        try container.encode(weakSkills, forKey: .weakSkills)
        try container.encode(strongSkills, forKey: .strongSkills)
        try container.encodeIfPresent(lastPlacementAt, forKey: .lastPlacementAt)
        try container.encode(dailyGoal, forKey: .dailyGoal)
        try container.encodeIfPresent(voiceID, forKey: .voiceID)
        try container.encode(selectedTopics, forKey: .selectedTopics)
        try container.encode(enabledPracticeSteps, forKey: .enabledPracticeSteps)
        try container.encode(settings, forKey: .settings)
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
        try container.encode(energy, forKey: .energy)
        try container.encode(unlockedAchievementIDs, forKey: .unlockedAchievementIDs)
        try container.encodeIfPresent(currentDailyPack, forKey: .currentDailyPack)
    }

    var dailyWords: [WordEntry] {
        let pack = currentDailyPack ?? WordSelectionEngine.dailyPack(for: self)
        let wordsByID = Dictionary(uniqueKeysWithValues: WordBank.all.map { ($0.id, $0) })
        let selected = pack.allWordIDs.compactMap { wordsByID[$0] }
        return selected.isEmpty ? WordBank.dailyWords(for: self) : Array(selected.prefix(dailyGoal))
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
            currentDailyPack = nil
        }

        if dailyProgress[today] == nil {
            dailyProgress[today] = .empty(for: today)
        }

        if currentDailyPack?.dateKey != today {
            currentDailyPack = WordSelectionEngine.dailyPack(for: self)
        }

        syncSettings()
    }

    mutating func applyPlacementResult(_ result: PlacementResult) {
        placementResult = result
        atlasScore = max(0, min(result.atlasScore, 600))
        score0To160 = LearningLevel.legacyScore(fromAtlasScore: atlasScore)
        currentLevel = result.cefrLevel
        skillScores = result.skillScores
        weakSkills = result.weakSkills
        strongSkills = result.strongSkills
        lastPlacementAt = result.createdAt
        dailyGoal = result.recommendedDailyGoal
        selectedTopics = result.recommendedTopics
        unknownWordIDs = Array(Set(unknownWordIDs + result.unknownWordIDs)).sorted()
        currentDailyPack = WordSelectionEngine.dailyPack(for: self)
        syncSettings()
    }

    mutating func applyAtlasScore(_ score: Int) {
        atlasScore = max(0, min(score, 600))
        score0To160 = LearningLevel.legacyScore(fromAtlasScore: atlasScore)
        currentLevel = LearningLevel.from(atlasScore: atlasScore)
    }

    mutating func applyAtlasScoreDelta(_ delta: Int) {
        guard delta != 0 else { return }
        applyAtlasScore(atlasScore + delta)
    }

    mutating func syncSettings() {
        settings.appLanguage = appLanguage
        settings.dailyGoal = dailyGoal
        settings.selectedTopics = selectedTopics
        settings.preferredVoice = voiceID ?? .american
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
        MemoryEngineV2.record(word: word, mode: mode, isCorrect: isCorrect, profile: &self)
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
        MemoryEngineV2.record(word: word, mode: mode, isCorrect: isCorrect, profile: &profile)
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
        let pack = WordSelectionEngine.dailyPack(for: profile, words: all)
        var result = pack.allWordIDs.compactMap { id in all.first { $0.id == id } }

        for word in rotated(all, seed: AtlasProfile.todayKey().hashValue + profile.atlasScore) {
            guard !result.contains(where: { $0.id == word.id }) else { continue }
            result.append(word)
            if result.count == profile.dailyGoal { break }
        }

        return Array(result.prefix(profile.dailyGoal))
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
        let english = word.english.lowercased()
        let blockedPartsOfSpeech: Set<String> = [
            "article",
            "conjunction",
            "determiner",
            "function",
            "interjection",
            "preposition",
            "pronoun"
        ]
        let blockedWords: Set<String> = [
            "a", "about", "all", "also", "am", "an", "and", "any", "are", "as", "at", "be", "but",
            "by", "can", "could", "do", "does", "each", "even", "every", "for", "from", "had", "has",
            "have", "he", "her", "here", "him", "his", "how", "if", "in", "is", "it", "its", "just",
            "may", "me", "more", "most", "must", "my", "no", "not", "of", "on", "one", "only", "or",
            "our", "own", "same", "she", "should", "so", "some", "such", "than", "that", "the",
            "their", "them", "there", "these", "they", "this", "those", "to", "too", "under", "up",
            "us", "very", "was", "we", "were", "what", "when", "where", "which", "while", "who",
            "why", "will", "with", "would", "you", "your",
            "los", "pop",
            "abortion", "bomb", "cocaine", "die", "drug", "kill", "knife", "malaria", "racism",
            "tuberculosis", "virus", "vodka", "vomit", "war"
        ]

        return word.hasReadableRussian &&
            word.english.rangeOfCharacter(from: .decimalDigits) == nil &&
            !blockedPartsOfSpeech.contains(word.partOfSpeech.lowercased()) &&
            !blockedWords.contains(english) &&
            english.count >= 4
    }

    static func translationChoices(for word: WordEntry) -> [String] {
        let closePool = all
            .filter {
                $0.id != word.id &&
                    abs($0.level.order - word.level.order) <= 1 &&
                    $0.hasReadableRussian &&
                    ($0.partOfSpeech == word.partOfSpeech || $0.topic == word.topic)
            }
            .map(\.russian)
        let fallbackPool = all
            .filter { $0.id != word.id && abs($0.level.order - word.level.order) <= 1 && $0.hasReadableRussian }
            .map(\.russian)

        return choices(correct: word.russian, distractors: closePool.isEmpty ? fallbackPool : closePool, seed: seed(for: word.id))
    }

    static func englishChoices(for word: WordEntry) -> [String] {
        let pool = all
            .filter { $0.id != word.id && abs($0.level.order - word.level.order) <= 1 && $0.partOfSpeech == word.partOfSpeech }
            .map(\.english)
        let fallback = all
            .filter { $0.id != word.id && abs($0.level.order - word.level.order) <= 1 }
            .map(\.english)
        return choices(correct: word.english, distractors: pool.isEmpty ? fallback : pool, seed: seed(for: word.id) + 31)
    }

    static func synonymChoices(for word: WordEntry) -> [String] {
        let correct = word.synonyms.first ?? "no exact synonym"
        let pool = all
            .filter { $0.id != word.id && $0.partOfSpeech == word.partOfSpeech }
            .map(\.english)
        return choices(correct: correct, distractors: pool, seed: seed(for: word.english) + 47)
    }

    static func clozeChoices(for word: WordEntry) -> [String] {
        let closePool = all
            .filter {
                $0.id != word.id &&
                    abs($0.level.order - word.level.order) <= 1 &&
                    $0.partOfSpeech == word.partOfSpeech
            }
            .map(\.english)
        let fallbackPool = all
            .filter { $0.id != word.id && abs($0.level.order - word.level.order) <= 1 }
            .map(\.english)

        return choices(correct: word.english, distractors: closePool.isEmpty ? fallbackPool : closePool, seed: seed(for: word.id) + 89)
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

enum PracticePlanner {
    static func sessionWords(
        from sourceWords: [WordEntry],
        profile: AtlasProfile,
        startWordID: WordEntry.ID?
    ) -> [WordEntry] {
        WordSelectionEngine.wordsForSession(
            sourceWords: sourceWords,
            profile: profile,
            startWordID: startWordID
        )
    }

    static func questions(for words: [WordEntry], profile: AtlasProfile) -> [PracticeQuestion] {
        let plan = PracticeGameEngine.sessionPlan(words: words, profile: profile)
        let questions = plan.tasks.map(PracticeQuestion.init(task:))
        return questions.isEmpty ? [PracticeQuestion(wordID: WordBank.all[0].id, step: .meaningChoice)] : questions
    }

    private static func steps(for word: WordEntry, profile: AtlasProfile) -> [PracticeStep] {
        let memory = profile.wordProgress[word.id]
        let isUnknown = profile.unknownWordIDs.contains(word.id)
        let isNew = memory == nil || memory?.totalAttempts == 0
        let isWeak = isUnknown ||
            memory?.isDue() == true ||
            (memory?.wrongCount ?? 0) > 0 ||
            ((memory?.totalAttempts ?? 0) > 0 && (memory?.mastery ?? 0) < 45)
        let isStretch = word.level.order > profile.currentLevel.order
        let isStrong = (memory?.mastery ?? 0) >= 70
        let enabledSteps = profile.enabledPracticeSteps.isEmpty ? PracticeStep.allCases : profile.enabledPracticeSteps

        func enabled(_ steps: [PracticeStep]) -> [PracticeStep] {
            let filtered = steps.filter { enabledSteps.contains($0) }
            return filtered.isEmpty ? [enabledSteps.first ?? .meaningChoice] : filtered
        }

        if isWeak || isNew {
            return enabled([.meaningChoice, .ruToEnglishTiles, .clozeWord])
        }

        if isStrong || isStretch {
            return enabled([.listenTiles, .wordOrder, .clozeWord, .speechRepeat])
        }

        return enabled([.meaningChoice, .listenTiles, .clozeWord, .wordOrder])
    }

    private static func isPracticeReady(_ word: WordEntry) -> Bool {
        word.hasReadableRussian &&
            word.english.rangeOfCharacter(from: .decimalDigits) == nil &&
            !word.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
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
