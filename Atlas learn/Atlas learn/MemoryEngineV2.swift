//
//  MemoryEngineV2.swift
//  Atlas learn
//

import Foundation

enum ErrorType: String, Codable, CaseIterable, Identifiable, Hashable {
    case meaning
    case spelling
    case listening
    case pronunciation
    case grammar
    case collocation
    case wordOrder
    case falseFriend
    case slowRecall

    var id: String { rawValue }
}

enum MemoryEngineV2 {
    static func record(
        word: WordEntry,
        mode: PracticeMode,
        isCorrect: Bool,
        profile: inout AtlasProfile,
        errorType: ErrorType? = nil,
        responseTime: TimeInterval? = nil,
        confidence: Double? = nil
    ) -> Int {
        profile.prepareForToday()

        var memory = profile.wordProgress[word.id] ?? .fresh
        let now = Date()
        let xp = isCorrect ? xpReward(for: mode, profile: profile) : 0

        memory.exposures += 1
        memory.lastPracticedAt = now
        memory.lastModes.append(mode)
        if memory.lastModes.count > 8 {
            memory.lastModes = Array(memory.lastModes.suffix(8))
        }

        if let responseTime {
            let attempts = max(memory.exposures, 1)
            memory.averageResponseTime = ((memory.averageResponseTime * Double(attempts - 1)) + responseTime) / Double(attempts)
            if responseTime > Double(mode.expectedSeconds) * 1.8 {
                memory.errorTypes[.slowRecall, default: 0] += 1
            }
        }

        if let confidence {
            memory.confidenceHistory.append(min(max(confidence, 0), 1))
            if memory.confidenceHistory.count > 12 {
                memory.confidenceHistory = Array(memory.confidenceHistory.suffix(12))
            }
        }

        if isCorrect {
            memory.correctCount += 1
            memory.streak += 1
            memory.mastery = min(100, memory.mastery + masteryGain(for: mode, memory: memory, word: word, profile: profile))
            memory.stability = min(120, max(1, memory.stability * 1.35 + Double(memory.streak)))
            memory.difficulty = max(0.05, memory.difficulty - 0.04)
            memory.retrievability = min(1, memory.retrievability + 0.16)
            memory.dueAt = Calendar.current.date(byAdding: .day, value: intervalDays(for: memory, profile: profile), to: now)
            memory.boredomScore = min(1, memory.boredomScore + 0.12)

            profile.markCompleted(word.id)
            if memory.mastery >= 45 {
                profile.unknownWordIDs.removeAll { $0 == word.id }
            }
            profile.applyAtlasScoreDelta(scoreDelta(for: word, mode: mode, profile: profile, isCorrect: true))
        } else {
            memory.wrongCount += 1
            memory.streak = 0
            memory.mastery = max(0, memory.mastery - masteryLoss(for: mode))
            memory.stability = max(0.5, memory.stability * 0.72)
            memory.difficulty = min(1, memory.difficulty + 0.08)
            memory.retrievability = max(0, memory.retrievability - 0.22)
            memory.dueAt = Calendar.current.date(byAdding: .hour, value: dueHoursAfterError(profile: profile), to: now)
            memory.boredomScore = min(1, memory.boredomScore + 0.06)
            profile.addUnknown(word.id)

            if let errorType {
                memory.errorTypes[errorType, default: 0] += 1
            } else {
                memory.errorTypes[mode.defaultErrorType, default: 0] += 1
            }

            profile.applyAtlasScoreDelta(scoreDelta(for: word, mode: mode, profile: profile, isCorrect: false))
        }

        profile.wordProgress[word.id] = memory
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

        if profile.practiceHistory.count > 700 {
            profile.practiceHistory = Array(profile.practiceHistory.prefix(700))
        }

        if isCorrect && profile.streak == 0 {
            profile.streak = 1
        } else if isCorrect && daily.correct == 1 {
            profile.streak += 1
        }

        AchievementEngine.applyAutomaticUnlocks(profile: &profile)
        return xp
    }

    private static func xpReward(for mode: PracticeMode, profile: AtlasProfile) -> Int {
        let streakMultiplier = profile.streak >= 7 ? 1.10 : (profile.streak >= 3 ? 1.05 : 1.0)
        let multiplier = min(streakMultiplier, 1.25)
        return Int((Double(mode.xpReward) * multiplier).rounded())
    }

    private static func masteryGain(for mode: PracticeMode, memory: WordMemory, word: WordEntry, profile: AtlasProfile) -> Int {
        let streakBonus = min(memory.streak, 3)
        let challengeBonus = mode == .bossChallenge ? 5 : 0
        let levelBonus = word.level.order >= profile.currentLevel.order ? 2 : 0
        return mode.masteryWeight + streakBonus + challengeBonus + levelBonus
    }

    private static func masteryLoss(for mode: PracticeMode) -> Int {
        switch mode {
        case .bossChallenge:
            14
        case .dictationSprint, .speakingEcho, .speechRepeat:
            12
        default:
            10
        }
    }

    private static func intervalDays(for memory: WordMemory, profile: AtlasProfile) -> Int {
        let base: Int
        switch memory.mastery {
        case 0..<25: base = 1
        case 25..<45: base = 2
        case 45..<65: base = 4
        case 65..<82: base = 7
        case 82..<94: base = 14
        default: base = 30
        }

        switch profile.settings.reviewAggressiveness {
        case .light:
            return Int(Double(base) * 1.25)
        case .balanced:
            return base
        case .strict:
            return max(1, Int(Double(base) * 0.75))
        }
    }

    private static func dueHoursAfterError(profile: AtlasProfile) -> Int {
        switch profile.settings.reviewAggressiveness {
        case .light: 24
        case .balanced: 18
        case .strict: 8
        }
    }

    private static func scoreDelta(for word: WordEntry, mode: PracticeMode, profile: AtlasProfile, isCorrect: Bool) -> Int {
        let isScoreBearing = mode.isAtlasScoreBearing
        guard isScoreBearing else { return 0 }

        if isCorrect {
            if word.level.order < profile.currentLevel.order { return min(1, max(0, word.level.order - profile.currentLevel.order + 2)) }
            if word.level.order == profile.currentLevel.order { return mode == .bossChallenge ? 4 : 2 }
            return mode == .bossChallenge ? 5 : 3
        } else {
            return mode == .bossChallenge ? -3 : 0
        }
    }
}
