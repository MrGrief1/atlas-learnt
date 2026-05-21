//
//  MasteryEngine.swift
//  Atlas learn
//

import Foundation

enum MasteryEngine {
    static func apply(
        result: LessonTaskResult,
        word: WordEntry?,
        profile: inout AtlasProfile
    ) {
        profile.prepareForToday()

        guard let word else {
            applyXPOnly(result, profile: &profile)
            return
        }

        var memory = profile.wordProgress[word.id] ?? .fresh
        let now = result.createdAt
        let mode = result.type.practiceMode

        memory.exposures += 1
        memory.lastPracticedAt = now
        memory.lastModes.append(mode)
        if memory.lastModes.count > 8 {
            memory.lastModes = Array(memory.lastModes.suffix(8))
        }

        if result.responseTime > 0 {
            let attempts = max(memory.exposures, 1)
            memory.averageResponseTime = ((memory.averageResponseTime * Double(attempts - 1)) + result.responseTime) / Double(attempts)
            if result.responseTime > Double(mode.expectedSeconds) * 1.8 {
                memory.errorTypes[.slowRecall, default: 0] += 1
            }
        }

        if result.isCorrect {
            memory.correctCount += 1
            memory.streak += 1
            memory.mastery = min(100, memory.mastery + max(result.masteryDelta, 0))
            memory.stability = min(120, max(1, memory.stability * 1.25 + Double(min(memory.streak, 4))))
            memory.difficulty = max(0.05, memory.difficulty - 0.03)
            memory.retrievability = min(1, memory.retrievability + 0.14)
            memory.dueAt = dueDate(forMastery: memory.mastery, hadMistake: false, from: now)
            memory.boredomScore = min(1, memory.boredomScore + 0.08)
            profile.markCompleted(word.id)
            if memory.mastery >= 45 {
                profile.unknownWordIDs.removeAll { $0 == word.id }
            }
        } else {
            memory.wrongCount += 1
            memory.streak = 0
            memory.mastery = max(0, memory.mastery + result.masteryDelta)
            memory.stability = max(0.5, memory.stability * 0.78)
            memory.difficulty = min(1, memory.difficulty + 0.06)
            memory.retrievability = max(0, memory.retrievability - 0.18)
            memory.dueAt = dueDate(forMastery: memory.mastery, hadMistake: true, from: now)
            memory.boredomScore = min(1, memory.boredomScore + 0.04)
            memory.errorTypes[errorType(for: result), default: 0] += 1
            profile.addUnknown(word.id)
        }

        profile.wordProgress[word.id] = memory
        applyXPAndDaily(result, word: word, profile: &profile)
        AchievementEngine.applyAutomaticUnlocks(profile: &profile)
    }

    static func dueDate(forMastery mastery: Int, hadMistake: Bool, from date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let base: Date?

        switch mastery {
        case ..<30:
            base = calendar.date(byAdding: .hour, value: 2, to: date)
        case 30..<50:
            base = calendar.date(byAdding: .day, value: 1, to: date)
        case 50..<70:
            base = calendar.date(byAdding: .day, value: 2, to: date)
        case 70..<85:
            base = calendar.date(byAdding: .day, value: 4, to: date)
        case 85..<95:
            base = calendar.date(byAdding: .day, value: 7, to: date)
        default:
            base = calendar.date(byAdding: .day, value: 14, to: date)
        }

        guard hadMistake else {
            return base ?? date
        }

        if mastery < 50 {
            return calendar.date(byAdding: .hour, value: 2, to: date) ?? date
        }

        let shortened = max(4, Int((base?.timeIntervalSince(date) ?? 86_400) / 3600 / 2))
        return calendar.date(byAdding: .hour, value: shortened, to: date) ?? date
    }

    static func masteryLabel(for mastery: Int, language: AppLanguage) -> String {
        switch mastery {
        case 0..<20:
            language.text(ru: "Seen", en: "Seen")
        case 20..<40:
            language.text(ru: "Recognized", en: "Recognized")
        case 40..<60:
            language.text(ru: "Understood", en: "Understood")
        case 60..<75:
            language.text(ru: "Recall", en: "Recall")
        case 75..<90:
            language.text(ru: "Active", en: "Active")
        default:
            language.text(ru: "Mastered", en: "Mastered")
        }
    }

    private static func applyXPOnly(_ result: LessonTaskResult, profile: inout AtlasProfile) {
        profile.xp += result.xp
        let today = AtlasProfile.todayKey(date: result.createdAt)
        var daily = profile.dailyProgress[today] ?? .empty(for: today)
        daily.xp += result.xp
        if result.isCorrect {
            daily.correct += 1
        } else {
            daily.wrong += 1
        }
        profile.dailyProgress[today] = daily
    }

    private static func applyXPAndDaily(_ result: LessonTaskResult, word: WordEntry, profile: inout AtlasProfile) {
        profile.xp += result.xp

        let today = AtlasProfile.todayKey(date: result.createdAt)
        var daily = profile.dailyProgress[today] ?? .empty(for: today)
        daily.xp += result.xp
        daily.dueCountAtStart = max(daily.dueCountAtStart, profile.dueWordsCount)
        if result.isCorrect {
            daily.correct += 1
            daily.completedWordIDs.appendUnique(word.id)
        } else {
            daily.wrong += 1
        }
        profile.dailyProgress[today] = daily

        profile.practiceHistory.insert(
            PracticeRecord(
                id: UUID(),
                date: result.createdAt,
                wordID: word.id,
                wordEnglish: word.english,
                mode: result.type.practiceMode,
                isCorrect: result.isCorrect,
                xp: result.xp,
                level: word.level
            ),
            at: 0
        )

        if profile.practiceHistory.count > 700 {
            profile.practiceHistory = Array(profile.practiceHistory.prefix(700))
        }

        if result.isCorrect && profile.streak == 0 {
            profile.streak = 1
        } else if result.isCorrect && daily.correct == 1 {
            profile.streak += 1
        }
    }

    private static func errorType(for result: LessonTaskResult) -> ErrorType {
        switch result.skill {
        case .listening:
            .listening
        case .spelling:
            .spelling
        case .grammar:
            .grammar
        case .speaking:
            .pronunciation
        case .writing, .recall:
            .slowRecall
        case .meaning, .context:
            .meaning
        }
    }
}

