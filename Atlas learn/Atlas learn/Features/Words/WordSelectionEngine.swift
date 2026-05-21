//
//  WordSelectionEngine.swift
//  Atlas learn
//

import Foundation

struct DailyPack: Codable, Equatable {
    let dateKey: String
    let newWords: [String]
    let reviewWords: [String]
    let weakWords: [String]
    let stretchWords: [String]
    let savedWords: [String]
    let bossWordIDs: [String]

    nonisolated var allWordIDs: [String] {
        var seen = Set<String>()
        var result: [String] = []
        for id in reviewWords + weakWords + newWords + stretchWords + savedWords + bossWordIDs where !seen.contains(id) {
            seen.insert(id)
            result.append(id)
        }
        return result
    }
}

enum WordSelectionEngine {
    nonisolated static func dailyPack(for profile: AtlasProfile, words: [WordEntry] = WordBank.all, now: Date = Date()) -> DailyPack {
        let goal = max(profile.dailyGoal, 1)
        let dateKey = AtlasProfile.todayKey(date: now)
        let rankedWords = rankedCandidates(words, profile: profile, now: now)
        let due = rankedWords.filter { word in
            profile.wordProgress[word.id]?.isDue(on: now) == true
        }
        let weak = rankedWords.filter { word in
            profile.unknownWordIDs.contains(word.id) ||
                (profile.wordProgress[word.id]?.mastery ?? 100) < 40 ||
                (profile.wordProgress[word.id]?.wrongCount ?? 0) > 0
        }
        let current = rankedWords.filter { word in
            word.level == profile.currentLevel && (profile.wordProgress[word.id]?.totalAttempts ?? 0) == 0
        }
        let stretch = rankedWords.filter { word in
            profile.settings.stretchModeEnabled && word.level == profile.currentLevel.next
        }
        let saved = rankedWords.filter { word in
            profile.savedWordIDs.contains(word.id) || profile.favoriteWordIDs.contains(word.id)
        }

        let dueCount = due.count
        let reviewTarget: Int
        let weakTarget: Int
        let newTarget: Int
        let stretchTarget: Int
        let savedTarget: Int

        if dueCount > Int(Double(goal) * 2.5) {
            reviewTarget = Int(Double(goal) * 0.7)
            weakTarget = goal - reviewTarget
            newTarget = 0
            stretchTarget = 0
            savedTarget = 0
        } else if dueCount > Int(Double(goal) * 1.5) {
            reviewTarget = Int(Double(goal) * 0.5)
            weakTarget = Int(Double(goal) * 0.3)
            newTarget = max(0, goal - reviewTarget - weakTarget - 1)
            stretchTarget = 1
            savedTarget = 0
        } else {
            reviewTarget = max(1, Int((Double(goal) * 0.35).rounded()))
            weakTarget = max(1, Int((Double(goal) * 0.25).rounded()))
            newTarget = max(1, min(profile.settings.newWordsPerDayLimit, Int((Double(goal) * 0.25).rounded())))
            stretchTarget = profile.settings.stretchModeEnabled ? max(0, Int((Double(goal) * 0.10).rounded())) : 0
            savedTarget = max(0, goal - reviewTarget - weakTarget - newTarget - stretchTarget)
        }

        var used = Set<String>()
        func take(_ candidates: [WordEntry], _ count: Int) -> [String] {
            guard count > 0 else { return [] }
            var ids: [String] = []
            for word in candidates where !used.contains(word.id) {
                ids.append(word.id)
                used.insert(word.id)
                if ids.count >= count { break }
            }
            return ids
        }

        let reviewIDs = take(due, reviewTarget)
        let weakIDs = take(weak, weakTarget)
        let newIDs = take(current, newTarget)
        let stretchIDs = take(stretch, stretchTarget)
        let savedIDs = take(saved, savedTarget)
        let bossIDs = Array((reviewIDs + weakIDs + stretchIDs).prefix(2))

        return DailyPack(
            dateKey: dateKey,
            newWords: newIDs,
            reviewWords: reviewIDs,
            weakWords: weakIDs,
            stretchWords: stretchIDs,
            savedWords: savedIDs,
            bossWordIDs: bossIDs
        )
    }

    nonisolated static func wordsForSession(
        sourceWords: [WordEntry],
        profile: AtlasProfile,
        startWordID: WordEntry.ID?,
        words: [WordEntry] = WordBank.all,
        now: Date = Date()
    ) -> [WordEntry] {
        let targetCount: Int
        switch profile.settings.sessionLength {
        case .quick:
            targetCount = 3
        case .normal:
            targetCount = 5
        case .deep:
            targetCount = 6
        }

        var result: [WordEntry] = []
        func append(_ candidates: [WordEntry]) {
            for word in candidates where isPracticeReady(word) {
                guard !result.contains(where: { $0.id == word.id }) else { continue }
                result.append(word)
                if result.count >= targetCount { return }
            }
        }

        if let startWordID {
            append(sourceWords.filter { $0.id == startWordID })
            append(words.filter { $0.id == startWordID })
        }

        let pack = dailyPack(for: profile, words: words, now: now)
        append(pack.allWordIDs.compactMap { id in words.first { $0.id == id } })
        append(sourceWords)
        append(sortedCandidates(words, profile: profile, now: now) { _ in true })

        return Array(result.prefix(targetCount))
    }

    nonisolated static func priority(for word: WordEntry, profile: AtlasProfile, now: Date = Date()) -> Double {
        let memory = profile.wordProgress[word.id] ?? .fresh
        var score = 0.0

        if memory.dueAt.map({ $0 <= now }) == true { score += 100 }
        if memory.mastery < 40 { score += 60 }
        if profile.unknownWordIDs.contains(word.id) { score += 70 }
        if profile.selectedTopics.contains(word.topic) { score += 25 }
        if profile.savedWordIDs.contains(word.id) || profile.favoriteWordIDs.contains(word.id) { score += 15 }
        if word.level == profile.currentLevel.next { score += profile.settings.stretchModeEnabled ? 10 : -40 }

        score += levelFitScore(word.level, profile.currentLevel)
        score += frequencyScore(word.frequencyRank)
        score -= recentlySeenPenalty(memory.lastPracticedAt, now: now)
        score -= memory.boredomScore * 30
        score -= sameModeFatigue(memory.lastModes)

        return score
    }

    nonisolated private static func sortedCandidates(
        _ words: [WordEntry],
        profile: AtlasProfile,
        now: Date,
        where predicate: (WordEntry) -> Bool
    ) -> [WordEntry] {
        rankedCandidates(words, profile: profile, now: now)
            .filter(predicate)
    }

    nonisolated private static func rankedCandidates(
        _ words: [WordEntry],
        profile: AtlasProfile,
        now: Date
    ) -> [WordEntry] {
        words
            .filter(isPracticeReady)
            .map { word in
                (word: word, score: priority(for: word, profile: profile, now: now))
            }
            .sorted { left, right in
                if left.score != right.score { return left.score > right.score }
                return left.word.english.localizedCaseInsensitiveCompare(right.word.english) == .orderedAscending
            }
            .map(\.word)
    }

    nonisolated private static func isPracticeReady(_ word: WordEntry) -> Bool {
        word.hasReadableRussian &&
            word.english.rangeOfCharacter(from: .decimalDigits) == nil &&
            !word.english.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    nonisolated private static func levelFitScore(_ level: LearningLevel, _ current: LearningLevel) -> Double {
        let distance = abs(level.order - current.order)
        if distance == 0 { return 35 }
        if level.order == current.order + 1 { return 18 }
        return -Double(distance * 16)
    }

    nonisolated private static func frequencyScore(_ rank: Int?) -> Double {
        guard let rank, rank > 0 else { return 0 }
        return max(0, 20 - log(Double(rank)))
    }

    nonisolated private static func recentlySeenPenalty(_ date: Date?, now: Date) -> Double {
        guard let date else { return 0 }
        let hours = now.timeIntervalSince(date) / 3600
        if hours < 2 { return 75 }
        if hours < 24 { return 32 }
        if hours < 72 { return 12 }
        return 0
    }

    nonisolated private static func sameModeFatigue(_ modes: [PracticeMode]) -> Double {
        guard let last = modes.last else { return 0 }
        return Double(modes.suffix(3).filter { $0 == last }.count * 8)
    }
}
