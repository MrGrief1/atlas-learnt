//
//  SettingsModels.swift
//  Atlas learn
//

import Foundation

enum SessionLength: String, CaseIterable, Codable, Identifiable {
    case quick
    case normal
    case deep

    var id: String { rawValue }

    var taskRange: ClosedRange<Int> {
        switch self {
        case .quick: 6...6
        case .normal: 10...14
        case .deep: 18...24
        }
    }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .quick:
            language.text(ru: "Быстро", en: "Quick")
        case .normal:
            language.text(ru: "Нормально", en: "Normal")
        case .deep:
            language.text(ru: "Глубоко", en: "Deep")
        }
    }
}

enum ReviewAggressiveness: String, CaseIterable, Codable, Identifiable {
    case light
    case balanced
    case strict

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .light:
            language.text(ru: "Мягко", en: "Light")
        case .balanced:
            language.text(ru: "Баланс", en: "Balanced")
        case .strict:
            language.text(ru: "Строго", en: "Strict")
        }
    }
}

enum GameVarietyLevel: String, CaseIterable, Codable, Identifiable {
    case stable
    case balanced
    case experimental

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .stable:
            language.text(ru: "Стабильно", en: "Stable")
        case .balanced:
            language.text(ru: "Разнообразно", en: "Balanced")
        case .experimental:
            language.text(ru: "Эксперимент", en: "Experimental")
        }
    }
}

struct LearningSettings: Codable, Equatable {
    var appLanguage: AppLanguage
    var dailyGoal: Int
    var sessionLength: SessionLength
    var selectedTopics: [String]
    var reviewAggressiveness: ReviewAggressiveness
    var newWordsPerDayLimit: Int
    var stretchModeEnabled: Bool
    var speechEnabled: Bool
    var listeningEnabled: Bool
    var aiContentEnabled: Bool
    var gameVariety: GameVarietyLevel
    var strictAnswerChecking: Bool
    var preferredVoice: SpeechVoiceOption
    var reminderEnabled: Bool

    static let `default` = LearningSettings(
        appLanguage: .russian,
        dailyGoal: 7,
        sessionLength: .normal,
        selectedTopics: ["Everyday", "Work", "Study"],
        reviewAggressiveness: .balanced,
        newWordsPerDayLimit: 4,
        stretchModeEnabled: true,
        speechEnabled: true,
        listeningEnabled: true,
        aiContentEnabled: true,
        gameVariety: .balanced,
        strictAnswerChecking: false,
        preferredVoice: .american,
        reminderEnabled: false
    )
}
