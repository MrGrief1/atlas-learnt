//
//  AchievementEngine.swift
//  Atlas learn
//

import Foundation

enum AchievementEngine {
    static let all: [Achievement] = [
        Achievement(id: "streak-3", titleRU: "Искра", titleEN: "Spark", descriptionRU: "3 дня подряд", descriptionEN: "3 day streak", icon: "sparkles", tier: .bronze, condition: .streak(days: 3), xpReward: 20),
        Achievement(id: "streak-7", titleRU: "Пламя", titleEN: "Flame", descriptionRU: "7 дней подряд", descriptionEN: "7 day streak", icon: "flame.fill", tier: .silver, condition: .streak(days: 7), xpReward: 45),
        Achievement(id: "streak-30", titleRU: "Привычка Atlas", titleEN: "Atlas Habit", descriptionRU: "30 дней подряд", descriptionEN: "30 day streak", icon: "calendar.badge.checkmark", tier: .gold, condition: .streak(days: 30), xpReward: 150),
        Achievement(id: "words-50", titleRU: "50 слов", titleEN: "50 words", descriptionRU: "Увидеть 50 слов", descriptionEN: "See 50 words", icon: "textformat", tier: .bronze, condition: .wordsSeen(count: 50), xpReward: 30),
        Achievement(id: "words-100", titleRU: "100 слов", titleEN: "100 words", descriptionRU: "Увидеть 100 слов", descriptionEN: "See 100 words", icon: "books.vertical", tier: .silver, condition: .wordsSeen(count: 100), xpReward: 60),
        Achievement(id: "words-500", titleRU: "500 слов", titleEN: "500 words", descriptionRU: "Увидеть 500 слов", descriptionEN: "See 500 words", icon: "globe", tier: .gold, condition: .wordsSeen(count: 500), xpReward: 180),
        Achievement(id: "mastered-100", titleRU: "100 освоено", titleEN: "100 mastered", descriptionRU: "Освоить 100 слов", descriptionEN: "Master 100 words", icon: "checkmark.seal.fill", tier: .gold, condition: .masteredWords(count: 100), xpReward: 150),
        Achievement(id: "listening-1", titleRU: "Первый слух", titleEN: "First listening win", descriptionRU: "Верно выполнить аудио", descriptionEN: "Complete one listening task", icon: "waveform", tier: .bronze, condition: .listeningTasks(count: 1), xpReward: 15),
        Achievement(id: "listening-50", titleRU: "50 аудио", titleEN: "50 listening tasks", descriptionRU: "Выполнить 50 аудио", descriptionEN: "Complete 50 listening tasks", icon: "headphones", tier: .silver, condition: .listeningTasks(count: 50), xpReward: 80),
        Achievement(id: "speaking-1", titleRU: "Первый голос", titleEN: "First speaking task", descriptionRU: "Сделать речевое задание", descriptionEN: "Complete one speaking task", icon: "mic.fill", tier: .bronze, condition: .speakingTasks(count: 1), xpReward: 15),
        Achievement(id: "speaking-25", titleRU: "25 речевых", titleEN: "25 speaking tasks", descriptionRU: "Сделать 25 речевых заданий", descriptionEN: "Complete 25 speaking tasks", icon: "mic.badge.plus", tier: .silver, condition: .speakingTasks(count: 25), xpReward: 70),
        Achievement(id: "mistakes-10", titleRU: "10 ошибок исправлено", titleEN: "Fixed 10 mistakes", descriptionRU: "Вернуть слабые места в форму", descriptionEN: "Recover from 10 mistakes", icon: "arrow.triangle.2.circlepath", tier: .silver, condition: .fixedMistakes(count: 10), xpReward: 60),
        Achievement(id: "topic-travel", titleRU: "Travel Starter", titleEN: "Travel Starter", descriptionRU: "Начать тему Travel", descriptionEN: "Start the Travel topic", icon: "map", tier: .bronze, condition: .topic(topic: "Travel", count: 5), xpReward: 20),
        Achievement(id: "topic-work", titleRU: "Work Starter", titleEN: "Work Starter", descriptionRU: "Начать тему Work", descriptionEN: "Start the Work topic", icon: "briefcase", tier: .bronze, condition: .topic(topic: "Work", count: 5), xpReward: 20),
        Achievement(id: "topic-tech", titleRU: "Tech Explorer", titleEN: "Tech Explorer", descriptionRU: "Разобрать Tech слова", descriptionEN: "Explore Tech words", icon: "cpu", tier: .silver, condition: .topic(topic: "Tech", count: 10), xpReward: 45),
        Achievement(id: "topic-business", titleRU: "Business Core", titleEN: "Business Core", descriptionRU: "Разобрать Business слова", descriptionEN: "Explore Business words", icon: "chart.line.uptrend.xyaxis", tier: .silver, condition: .topic(topic: "Business", count: 10), xpReward: 45)
    ]

    static func requiredXP(for level: Int) -> Int {
        Int((80 * pow(Double(max(level, 1)), 1.35)).rounded())
    }

    static func xpLevel(for xp: Int) -> Int {
        var level = 1
        while xp >= requiredXP(for: level + 1) {
            level += 1
        }
        return level
    }

    static func applyAutomaticUnlocks(profile: inout AtlasProfile) {
        var awardedXP = 0
        for achievement in all where !profile.unlockedAchievementIDs.contains(achievement.id) && isUnlocked(achievement, profile: profile) {
            profile.unlockedAchievementIDs.append(achievement.id)
            awardedXP += achievement.xpReward
        }
        if awardedXP > 0 {
            profile.xp += awardedXP
        }
    }

    static func unlockedAchievements(for profile: AtlasProfile) -> [Achievement] {
        all.filter { profile.unlockedAchievementIDs.contains($0.id) }
    }

    private static func isUnlocked(_ achievement: Achievement, profile: AtlasProfile) -> Bool {
        switch achievement.condition {
        case .streak(let days):
            return profile.streak >= days
        case .perfectSessions:
            return profile.dailyProgress.values.contains { $0.wrong == 0 && $0.correct >= 5 }
        case .wordsSeen(let count):
            return profile.wordProgress.values.filter { $0.exposures > 0 }.count >= count
        case .masteredWords(let count):
            return profile.wordProgress.values.filter { $0.mastery >= 80 }.count >= count
        case .listeningTasks(let count):
            return profile.practiceHistory.filter { $0.mode.defaultErrorType == .listening && $0.isCorrect }.count >= count
        case .speakingTasks(let count):
            return profile.practiceHistory.filter { $0.mode.defaultErrorType == .pronunciation && $0.isCorrect }.count >= count
        case .fixedMistakes(let count):
            return profile.wordProgress.values.filter { $0.wrongCount > 0 && $0.streak > 0 }.count >= count
        case .masteredWeakWords(let count):
            return profile.wordProgress.values.filter { $0.wrongCount > 0 && $0.mastery >= 70 }.count >= count
        case .topic(let topic, let count):
            let practicedIDs = Set(profile.practiceHistory.map(\.wordID))
            return WordBank.all.filter { $0.topic == topic && practicedIDs.contains($0.id) }.count >= count
        case .hidden:
            return false
        }
    }
}
