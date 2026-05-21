//
//  PlacementItemBank.swift
//  Atlas learn
//

import Foundation

enum PlacementItemBank {
    static var all: [PlacementItem] {
        translationItems
    }

    private static var translationItems: [PlacementItem] {
        LearningLevel.allCases.flatMap { level in
            WordBank.all
                .filter { $0.level == level && WordBank.isAssessmentReady($0) }
                .sorted(by: assessmentSort)
                .prefix(12)
                .map { translationItem(for: $0) }
        }
    }

    private static func translationItem(for word: WordEntry) -> PlacementItem {
        PlacementItem(
            id: "vocab-translation-\(word.id)",
            skill: .vocabulary,
            type: .wordMeaning,
            cefrLevel: word.level,
            difficulty: difficulty(for: word.level),
            discrimination: 1.2,
            prompt: "Choose the translation.",
            text: word.english,
            audioText: nil,
            options: WordBank.translationChoices(for: word),
            correctAnswer: word.russian,
            acceptableAnswers: [word.russian],
            topic: word.topic,
            tags: ["word:\(word.id)", "translation"],
            estimatedSeconds: 10
        )
    }

    private static func assessmentSort(_ lhs: WordEntry, _ rhs: WordEntry) -> Bool {
        let lhsRank = lhs.frequencyRank ?? Int.max
        let rhsRank = rhs.frequencyRank ?? Int.max
        if lhsRank != rhsRank { return lhsRank < rhsRank }
        return lhs.english.localizedCaseInsensitiveCompare(rhs.english) == .orderedAscending
    }

    private static func difficulty(for level: LearningLevel) -> Double {
        switch level {
        case .a1: -2.5
        case .a2: -1.5
        case .b1: -0.5
        case .b2: 0.5
        case .c1: 1.5
        case .c2: 2.5
        }
    }
}
