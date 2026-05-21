//
//  LessonModels.swift
//  Atlas learn
//

import Foundation

enum LessonMode: String, Codable, CaseIterable, Identifiable {
    case daily
    case newWords
    case review
    case weakWords
    case wordDrill
    case listening
    case grammar
    case story
    case boss

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .daily: "map.fill"
        case .newWords: "sparkles"
        case .review: "arrow.clockwise"
        case .weakWords: "cross.case.fill"
        case .wordDrill: "target"
        case .listening: "headphones"
        case .grammar: "point.3.connected.trianglepath.dotted"
        case .story: "bubble.left.and.bubble.right.fill"
        case .boss: "crown.fill"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .daily:
            language.text(ru: "Урок дня", en: "Daily lesson")
        case .newWords:
            language.text(ru: "Новые слова", en: "New words")
        case .review:
            language.text(ru: "Повторение", en: "Review")
        case .weakWords:
            language.text(ru: "Слабые слова", en: "Weak words")
        case .wordDrill:
            language.text(ru: "Отработка слова", en: "Word drill")
        case .listening:
            language.text(ru: "Аудирование", en: "Listening")
        case .grammar:
            language.text(ru: "Грамматика", en: "Grammar")
        case .story:
            language.text(ru: "История", en: "Story")
        case .boss:
            language.text(ru: "Boss Check", en: "Boss Check")
        }
    }

    func subtitle(for language: AppLanguage) -> String {
        switch self {
        case .daily:
            language.text(ru: "Новые слова, повторение и финальная проверка.", en: "New words, review, and a final check.")
        case .newWords:
            language.text(ru: "Мягкий вход в свежую лексику.", en: "A gentle entry into fresh vocabulary.")
        case .review:
            language.text(ru: "Слова, которым пора вернуться.", en: "Words that are due to return.")
        case .weakWords:
            language.text(ru: "Разбор мест, где чаще всего сбиваешься.", en: "A repair pass for shaky words.")
        case .wordDrill:
            language.text(ru: "Один фокус: объяснить, узнать, вспомнить, использовать.", en: "One focus: explain, recognize, recall, use.")
        case .listening:
            language.text(ru: "Больше слуха и диктанта.", en: "More listening and dictation.")
        case .grammar:
            language.text(ru: "Грамматика через живые слова.", en: "Grammar through real words.")
        case .story:
            language.text(ru: "Мини-диалоги и контекст.", en: "Mini dialogues and context.")
        case .boss:
            language.text(ru: "Смешанная проверка без мягких подсказок.", en: "A mixed check without soft hints.")
        }
    }
}

enum LessonTaskType: String, Codable, CaseIterable, Identifiable {
    case introCard
    case meaningChoice
    case contextChoice
    case clozeChoice
    case activeRecallInput
    case translationTiles
    case wordOrder
    case audioChoice
    case dictation
    case matchingPairs
    case dialogueChoice
    case sentenceWriting
    case speechRepeat
    case mistakeClinic
    case finalCheck

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .introCard: "text.book.closed.fill"
        case .meaningChoice: "checklist"
        case .contextChoice: "text.quote"
        case .clozeChoice: "text.cursor"
        case .activeRecallInput: "brain.head.profile"
        case .translationTiles: "square.grid.3x3.fill"
        case .wordOrder: "text.line.first.and.arrowtriangle.forward"
        case .audioChoice: "speaker.wave.2.fill"
        case .dictation: "keyboard.fill"
        case .matchingPairs: "rectangle.on.rectangle"
        case .dialogueChoice: "bubble.left.and.bubble.right.fill"
        case .sentenceWriting: "pencil.and.scribble"
        case .speechRepeat: "mic.fill"
        case .mistakeClinic: "cross.case.fill"
        case .finalCheck: "flag.checkered"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .introCard:
            language.text(ru: "Разбор слова", en: "Word intro")
        case .meaningChoice:
            language.text(ru: "Выбери смысл", en: "Choose meaning")
        case .contextChoice:
            language.text(ru: "Контекст", en: "Context")
        case .clozeChoice:
            language.text(ru: "Пропуск", en: "Fill the blank")
        case .activeRecallInput:
            language.text(ru: "Вспомни сам", en: "Active recall")
        case .translationTiles:
            language.text(ru: "Плитки", en: "Tiles")
        case .wordOrder:
            language.text(ru: "Порядок слов", en: "Word order")
        case .audioChoice:
            language.text(ru: "На слух", en: "Audio")
        case .dictation:
            language.text(ru: "Диктант", en: "Dictation")
        case .matchingPairs:
            language.text(ru: "Пары", en: "Matching")
        case .dialogueChoice:
            language.text(ru: "Диалог", en: "Dialogue")
        case .sentenceWriting:
            language.text(ru: "Своя фраза", en: "Own sentence")
        case .speechRepeat:
            language.text(ru: "Повтори", en: "Repeat")
        case .mistakeClinic:
            language.text(ru: "Разбор ошибки", en: "Mistake clinic")
        case .finalCheck:
            language.text(ru: "Финальная проверка", en: "Final check")
        }
    }

    var xpReward: Int {
        switch self {
        case .introCard: 1
        case .meaningChoice: 5
        case .contextChoice, .clozeChoice, .dialogueChoice, .matchingPairs: 7
        case .audioChoice, .translationTiles, .wordOrder, .speechRepeat, .mistakeClinic: 8
        case .activeRecallInput, .dictation: 12
        case .sentenceWriting: 15
        case .finalCheck: 20
        }
    }

    var masteryReward: Int {
        switch self {
        case .introCard: 1
        case .meaningChoice, .matchingPairs: 4
        case .contextChoice, .clozeChoice, .audioChoice, .dialogueChoice, .translationTiles, .wordOrder: 6
        case .dictation, .speechRepeat: 10
        case .activeRecallInput: 12
        case .sentenceWriting: 14
        case .mistakeClinic: 5
        case .finalCheck: 15
        }
    }

    var defaultSkill: LessonSkill {
        switch self {
        case .introCard, .meaningChoice, .matchingPairs:
            .meaning
        case .contextChoice, .clozeChoice, .dialogueChoice:
            .context
        case .activeRecallInput, .finalCheck:
            .recall
        case .translationTiles, .wordOrder:
            .grammar
        case .audioChoice:
            .listening
        case .dictation:
            .spelling
        case .sentenceWriting:
            .writing
        case .speechRepeat:
            .speaking
        case .mistakeClinic:
            .recall
        }
    }

    var practiceMode: PracticeMode {
        switch self {
        case .introCard: .wordReveal
        case .meaningChoice, .matchingPairs: .meaningChoice
        case .contextChoice: .contextCloze
        case .clozeChoice: .clozeWord
        case .activeRecallInput: .wordBuilder
        case .translationTiles: .tileTranslation
        case .wordOrder: .wordOrder
        case .audioChoice: .audioCatch
        case .dictation: .dictationSprint
        case .dialogueChoice: .dialogueChoice
        case .sentenceWriting: .sentenceCompose
        case .speechRepeat: .speakingEcho
        case .mistakeClinic: .mistakeClinic
        case .finalCheck: .bossChallenge
        }
    }
}

enum LessonSkill: String, Codable, CaseIterable, Identifiable, Hashable {
    case meaning
    case context
    case recall
    case listening
    case spelling
    case grammar
    case speaking
    case writing

    var id: String { rawValue }
}

struct LessonRun: Codable, Identifiable, Equatable {
    let id: UUID
    let mode: LessonMode
    let startedAt: Date
    var finishedAt: Date?

    var targetWordIDs: [String]
    var reviewWordIDs: [String]
    var weakWordIDs: [String]

    var tasks: [LessonTask]
    var currentTaskIndex: Int
    var results: [LessonTaskResult]
    var mistakeQueue: [MistakeItem]

    var xpEarned: Int
    var energy: Int
    var combo: Int
    var maxCombo: Int

    init(
        id: UUID = UUID(),
        mode: LessonMode,
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        targetWordIDs: [String],
        reviewWordIDs: [String],
        weakWordIDs: [String],
        tasks: [LessonTask],
        currentTaskIndex: Int = 0,
        results: [LessonTaskResult] = [],
        mistakeQueue: [MistakeItem] = [],
        xpEarned: Int = 0,
        energy: Int = EnergyEngine.maxEnergy,
        combo: Int = 0,
        maxCombo: Int = 0
    ) {
        self.id = id
        self.mode = mode
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.targetWordIDs = targetWordIDs
        self.reviewWordIDs = reviewWordIDs
        self.weakWordIDs = weakWordIDs
        self.tasks = tasks
        self.currentTaskIndex = currentTaskIndex
        self.results = results
        self.mistakeQueue = mistakeQueue
        self.xpEarned = xpEarned
        self.energy = energy
        self.combo = combo
        self.maxCombo = maxCombo
    }

    var currentTask: LessonTask? {
        guard tasks.indices.contains(currentTaskIndex) else { return nil }
        return tasks[currentTaskIndex]
    }

    var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(currentTaskIndex) / Double(tasks.count)
    }

    var questionPosition: Int {
        min(currentTaskIndex + 1, max(tasks.count, 1))
    }

    var correctCount: Int {
        results.filter(\.isCorrect).count
    }

    var wrongCount: Int {
        results.filter { !$0.isCorrect }.count
    }

    var practicedWordIDs: [String] {
        Array(Set(results.compactMap(\.wordID)))
    }
}

struct LessonTask: Codable, Identifiable, Equatable {
    let id: UUID
    let type: LessonTaskType
    let wordID: String?
    let skill: LessonSkill
    let prompt: String
    let context: String?
    let audioText: String?
    let options: [String]
    let correctAnswer: String
    let acceptedAnswers: [String]
    let explanation: String?
    let difficulty: Int
    let xpReward: Int
    let masteryReward: Int

    init(
        id: UUID = UUID(),
        type: LessonTaskType,
        wordID: String?,
        skill: LessonSkill? = nil,
        prompt: String,
        context: String? = nil,
        audioText: String? = nil,
        options: [String] = [],
        correctAnswer: String,
        acceptedAnswers: [String] = [],
        explanation: String? = nil,
        difficulty: Int = 1,
        xpReward: Int? = nil,
        masteryReward: Int? = nil
    ) {
        self.id = id
        self.type = type
        self.wordID = wordID
        self.skill = skill ?? type.defaultSkill
        self.prompt = prompt
        self.context = context
        self.audioText = audioText
        self.options = options
        self.correctAnswer = correctAnswer
        self.acceptedAnswers = acceptedAnswers.isEmpty ? [correctAnswer] : acceptedAnswers
        self.explanation = explanation
        self.difficulty = difficulty
        self.xpReward = xpReward ?? type.xpReward
        self.masteryReward = masteryReward ?? type.masteryReward
    }
}

struct LessonTaskResult: Codable, Identifiable, Equatable {
    let id: UUID
    let taskID: UUID
    let wordID: String?
    let type: LessonTaskType
    let skill: LessonSkill
    let isCorrect: Bool
    let usedHint: Bool
    let responseTime: TimeInterval
    let xp: Int
    let masteryDelta: Int
    let createdAt: Date
}

struct MistakeItem: Codable, Identifiable, Equatable {
    let id: UUID
    let wordID: String
    let originalTaskType: LessonTaskType
    let skill: LessonSkill
    let wrongAnswer: String
    let correctAnswer: String
    let explanation: String
    var returnAfterTasks: Int
}

struct LessonAnswer: Equatable {
    var value: String
    var usedHint: Bool
    var didNotKnow: Bool
    var responseTime: TimeInterval

    static func answer(_ value: String, responseTime: TimeInterval, usedHint: Bool = false) -> LessonAnswer {
        LessonAnswer(value: value, usedHint: usedHint, didNotKnow: false, responseTime: responseTime)
    }

    static func dontKnow(responseTime: TimeInterval) -> LessonAnswer {
        LessonAnswer(value: "", usedHint: true, didNotKnow: true, responseTime: responseTime)
    }
}

struct LessonEvaluation: Equatable {
    let isCorrect: Bool
    let usedHint: Bool
    let didNotKnow: Bool
    let xp: Int
    let masteryDelta: Int
    let title: String
    let detail: String
    let correctAnswer: String
    let explanation: String
    let shouldScheduleMistake: Bool
}
