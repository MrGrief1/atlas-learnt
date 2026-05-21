//
//  AchievementModels.swift
//  Atlas learn
//

import Foundation

struct Achievement: Codable, Identifiable, Equatable {
    let id: String
    let titleRU: String
    let titleEN: String
    let descriptionRU: String
    let descriptionEN: String
    let icon: String
    let tier: AchievementTier
    let condition: AchievementCondition
    let xpReward: Int

    func title(for language: AppLanguage) -> String {
        language.text(ru: titleRU, en: titleEN)
    }

    func description(for language: AppLanguage) -> String {
        language.text(ru: descriptionRU, en: descriptionEN)
    }
}

enum AchievementTier: String, Codable, CaseIterable {
    case bronze
    case silver
    case gold
    case platinum
}

enum AchievementCondition: Codable, Equatable {
    case streak(days: Int)
    case perfectSessions(count: Int)
    case wordsSeen(count: Int)
    case masteredWords(count: Int)
    case listeningTasks(count: Int)
    case speakingTasks(count: Int)
    case fixedMistakes(count: Int)
    case masteredWeakWords(count: Int)
    case topic(topic: String, count: Int)
    case hidden(String)
}
