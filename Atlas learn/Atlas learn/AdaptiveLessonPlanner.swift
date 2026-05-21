//
//  AdaptiveLessonPlanner.swift
//  Atlas learn
//

import Foundation

enum AdaptiveLessonPlanner {
    static func taskTypes(
        for word: WordEntry,
        profile: AtlasProfile,
        mode: LessonMode
    ) -> [LessonTaskType] {
        let memory = profile.wordProgress[word.id] ?? .fresh

        if mode == .wordDrill {
            return wordDrillTypes(for: word, memory: memory, profile: profile)
        }

        if mode == .weakWords {
            return weakWordTypes(for: memory)
        }

        if mode == .review {
            return reviewTypes(for: memory)
        }

        if mode == .listening {
            return listeningTypes(for: memory)
        }

        if mode == .boss {
            return bossTypes(for: memory)
        }

        if memory.totalAttempts == 0 {
            return [.introCard, .meaningChoice, .contextChoice, .audioChoice, .activeRecallInput]
        }

        if memory.mastery < 35 {
            return [.meaningChoice, .contextChoice, .audioChoice, .mistakeClinic, .activeRecallInput]
        }

        if memory.mastery < 65 {
            return [.contextChoice, .clozeChoice, .dictation, .translationTiles, .activeRecallInput]
        }

        if memory.mastery < 85 {
            return [.activeRecallInput, .dictation, .sentenceWriting, .speechRepeat, .finalCheck]
        }

        return [.finalCheck, .sentenceWriting, .dictation, .activeRecallInput]
    }

    static func bestNextType(
        for word: WordEntry,
        profile: AtlasProfile,
        mode: LessonMode,
        previousTasks: [LessonTask]
    ) -> LessonTaskType {
        let memory = profile.wordProgress[word.id] ?? .fresh
        let candidates = taskTypes(for: word, profile: profile, mode: mode)

        for candidate in candidates {
            guard !shouldAvoid(candidate, previous: previousTasks) else { continue }
            guard !isFatigued(candidate, memory: memory) else { continue }
            return normalized(candidate)
        }

        for candidate in candidates {
            guard !shouldAvoid(candidate, previous: previousTasks) else { continue }
            return normalized(candidate)
        }

        return normalized(candidates.first ?? .meaningChoice)
    }

    private static func wordDrillTypes(
        for word: WordEntry,
        memory: WordMemory,
        profile: AtlasProfile
    ) -> [LessonTaskType] {
        if memory.totalAttempts == 0 {
            return [
                .introCard,
                .meaningChoice,
                .contextChoice,
                .audioChoice,
                .activeRecallInput,
                .clozeChoice,
                .sentenceWriting,
                .finalCheck
            ]
        }

        var result: [LessonTaskType] = []

        if memory.errorTypes[.meaning, default: 0] > 0 {
            result += [.meaningChoice, .contextChoice, .mistakeClinic]
        }

        if memory.errorTypes[.listening, default: 0] > 0 {
            result += [.audioChoice, .dictation]
        }

        if memory.errorTypes[.spelling, default: 0] > 0 {
            result += [.dictation, .activeRecallInput]
        }

        if memory.errorTypes[.grammar, default: 0] > 0 {
            result += [.wordOrder, .translationTiles, .clozeChoice]
        }

        if memory.errorTypes[.slowRecall, default: 0] > 0 {
            result += [.activeRecallInput, .finalCheck]
        }

        if result.isEmpty {
            result = [.contextChoice, .activeRecallInput, .dictation, .sentenceWriting, .finalCheck]
        }

        return result.uniqued()
    }

    private static func weakWordTypes(for memory: WordMemory) -> [LessonTaskType] {
        var result: [LessonTaskType] = [.mistakeClinic]

        if memory.errorTypes[.meaning, default: 0] > 0 {
            result += [.meaningChoice, .contextChoice]
        }

        if memory.errorTypes[.listening, default: 0] > 0 {
            result += [.audioChoice, .dictation]
        }

        if memory.errorTypes[.grammar, default: 0] > 0 {
            result += [.clozeChoice, .wordOrder, .translationTiles]
        }

        if memory.errorTypes[.spelling, default: 0] > 0 {
            result += [.dictation, .activeRecallInput]
        }

        result += [.activeRecallInput, .finalCheck]
        return result.uniqued()
    }

    private static func reviewTypes(for memory: WordMemory) -> [LessonTaskType] {
        if memory.mastery < 45 {
            return [.meaningChoice, .contextChoice, .audioChoice, .activeRecallInput]
        }

        if memory.mastery < 75 {
            return [.contextChoice, .dictation, .activeRecallInput, .translationTiles]
        }

        return [.activeRecallInput, .sentenceWriting, .finalCheck]
    }

    private static func listeningTypes(for memory: WordMemory) -> [LessonTaskType] {
        if memory.errorTypes[.listening, default: 0] > 0 {
            return [.audioChoice, .dictation, .speechRepeat, .mistakeClinic]
        }

        return [.audioChoice, .dictation, .contextChoice, .speechRepeat]
    }

    private static func bossTypes(for memory: WordMemory) -> [LessonTaskType] {
        if memory.mastery < 60 {
            return [.activeRecallInput, .dictation, .contextChoice, .finalCheck]
        }

        return [.finalCheck, .sentenceWriting, .dictation, .speechRepeat]
    }

    private static func shouldAvoid(_ next: LessonTaskType, previous: [LessonTask]) -> Bool {
        if previous.last?.type == next {
            return true
        }

        if previous.suffix(4).filter({ $0.type == next }).count >= 2 {
            return true
        }

        return false
    }

    private static func isFatigued(_ next: LessonTaskType, memory: WordMemory) -> Bool {
        guard memory.boredomScore >= 0.55 else { return false }
        return memory.lastModes.suffix(3).filter { $0 == next.practiceMode }.count >= 2
    }

    private static func normalized(_ type: LessonTaskType) -> LessonTaskType {
        type
    }
}

private extension Array where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
