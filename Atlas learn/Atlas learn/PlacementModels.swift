//
//  PlacementModels.swift
//  Atlas learn
//

import Foundation

enum PlacementSkill: String, Codable, CaseIterable, Identifiable, Hashable {
    case vocabulary
    case grammar
    case reading
    case listening
    case writing
    case speaking

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .vocabulary: "textformat"
        case .grammar: "text.badge.checkmark"
        case .reading: "book"
        case .listening: "waveform"
        case .writing: "pencil"
        case .speaking: "mic"
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .vocabulary:
            language.text(ru: "Словарь", en: "Vocabulary")
        case .grammar:
            language.text(ru: "Грамматика", en: "Grammar")
        case .reading:
            language.text(ru: "Чтение", en: "Reading")
        case .listening:
            language.text(ru: "Аудирование", en: "Listening")
        case .writing:
            language.text(ru: "Письмо", en: "Writing")
        case .speaking:
            language.text(ru: "Речь", en: "Speaking")
        }
    }
}

enum PlacementItemType: String, Codable, CaseIterable, Identifiable {
    case wordMeaning
    case cloze
    case sentenceOrder
    case readingDetail
    case readingInference
    case listeningChoice
    case dictation
    case shortWriting
    case speechRepeat

    var id: String { rawValue }
}

enum PlacementSelfEstimate: String, Codable, CaseIterable, Identifiable {
    case simplePhrases
    case shortTexts
    case newsSometimes
    case workOrStudy

    var id: String { rawValue }

    var thetaAdjustment: Double {
        switch self {
        case .simplePhrases: -0.25
        case .shortTexts: 0
        case .newsSometimes: 0.25
        case .workOrStudy: 0.5
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .simplePhrases:
            language.text(ru: "Знаю только простые фразы", en: "I know only simple phrases")
        case .shortTexts:
            language.text(ru: "Могу читать короткие тексты", en: "I can read short texts")
        case .newsSometimes:
            language.text(ru: "Иногда понимаю новости или видео", en: "I sometimes understand news or videos")
        case .workOrStudy:
            language.text(ru: "Использую английский в работе или учебе", en: "I use English at work or study")
        }
    }
}

enum AnswerConfidence: String, Codable, CaseIterable, Identifiable {
    case easy
    case ok
    case hard

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .easy: language.text(ru: "Легко", en: "Easy")
        case .ok: language.text(ru: "Ок", en: "OK")
        case .hard: language.text(ru: "Сложно", en: "Hard")
        }
    }
}

struct PlacementItem: Codable, Identifiable, Equatable {
    let id: String
    let skill: PlacementSkill
    let type: PlacementItemType
    let cefrLevel: LearningLevel
    let difficulty: Double
    let discrimination: Double
    let prompt: String
    let text: String?
    let audioText: String?
    let options: [String]
    let correctAnswer: String
    let acceptableAnswers: [String]
    let topic: String
    let tags: [String]
    let estimatedSeconds: Int
}

struct PlacementAnswer: Codable, Equatable, Identifiable {
    let id: UUID
    let itemID: String
    let skill: PlacementSkill
    let type: PlacementItemType
    let answer: String
    let correctAnswer: String
    let score: Double
    let timeSpent: TimeInterval
    let confidence: AnswerConfidence
    let createdAt: Date
    let wordID: String?

    init(
        id: UUID = UUID(),
        item: PlacementItem,
        answer: String,
        score: Double,
        timeSpent: TimeInterval,
        confidence: AnswerConfidence,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.itemID = item.id
        self.skill = item.skill
        self.type = item.type
        self.answer = answer
        self.correctAnswer = item.correctAnswer
        self.score = score
        self.timeSpent = timeSpent
        self.confidence = confidence
        self.createdAt = createdAt
        self.wordID = item.tags
            .first { $0.hasPrefix("word:") }
            .map { String($0.dropFirst("word:".count)) }
    }
}

struct PlacementResult: Codable, Equatable {
    var cefrLevel: LearningLevel
    var atlasScore: Int
    var confidence: Double
    var skillScores: [PlacementSkill: Int]
    var weakSkills: [PlacementSkill]
    var strongSkills: [PlacementSkill]
    var unknownWordIDs: [String]
    var recommendedTopics: [String]
    var recommendedDailyGoal: Int
    var createdAt: Date
}

struct PlacementAttempt: Codable, Identifiable, Equatable {
    let id: UUID
    var startedAt: Date
    var finishedAt: Date?
    var selectedStartLevel: LearningLevel
    var answers: [PlacementAnswer]
    var result: PlacementResult?

    init(
        id: UUID = UUID(),
        startedAt: Date = Date(),
        finishedAt: Date? = nil,
        selectedStartLevel: LearningLevel,
        answers: [PlacementAnswer] = [],
        result: PlacementResult? = nil
    ) {
        self.id = id
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.selectedStartLevel = selectedStartLevel
        self.answers = answers
        self.result = result
    }
}
