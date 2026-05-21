//
//  CurriculumEngine.swift
//  Atlas learn
//

import Foundation

enum CurriculumEngine {
    static func snapshot(for profile: AtlasProfile) -> CurriculumSnapshot {
        let sublevel = LearningLevel.sublevel(forAtlasScore: profile.atlasScore)
        let skillScores = profile.skillScores.isEmpty ? PlacementSkill.allCases.reduce(into: [:]) { $0[$1] = profile.atlasScore } : profile.skillScores
        let gaps = skillScores
            .filter { $0.value < profile.atlasScore - 35 }
            .sorted { $0.value < $1.value }
            .map(\.key)

        return CurriculumSnapshot(
            cefrLevel: profile.currentLevel,
            sublevel: sublevel,
            atlasScore: profile.atlasScore,
            skillGaps: gaps,
            recommendedPathTitle: recommendedPath(for: profile),
            gates: gates(for: profile)
        )
    }

    static func recommendedPath(for profile: AtlasProfile) -> String {
        let review = profile.currentLevel.order > LearningLevel.a1.order ? "\(LearningLevel.allCases[max(profile.currentLevel.order - 1, 0)].tag)/\(profile.currentLevel.tag) review" : "\(profile.currentLevel.tag) review"
        return "\(profile.currentLevel.tag) Core + \(review) + \(profile.currentLevel.next.tag) stretch"
    }

    static func gates(for profile: AtlasProfile) -> [CurriculumGate] {
        let nextStart = min(600, (profile.currentLevel.order + 1) * 100)
        let currentCoreWords = WordBank.all.filter { $0.level == profile.currentLevel }
        let masteredCore = currentCoreWords.filter { (profile.wordProgress[$0.id]?.mastery ?? 0) >= 70 }.count
        let coreMastery = currentCoreWords.isEmpty ? 0 : Int((Double(masteredCore) / Double(currentCoreWords.count) * 100).rounded())

        return [
            CurriculumGate(id: "score", title: "Atlas Score", isPassed: profile.atlasScore >= nextStart, currentValue: profile.atlasScore, requiredValue: nextStart),
            CurriculumGate(id: "core", title: "Core mastery", isPassed: coreMastery >= 70, currentValue: coreMastery, requiredValue: 70),
            CurriculumGate(id: "reading", title: "Reading", isPassed: (profile.skillScores[.reading] ?? profile.atlasScore) >= nextStart - 40, currentValue: profile.skillScores[.reading] ?? profile.atlasScore, requiredValue: nextStart - 40),
            CurriculumGate(id: "grammar", title: "Grammar", isPassed: (profile.skillScores[.grammar] ?? profile.atlasScore) >= nextStart - 45, currentValue: profile.skillScores[.grammar] ?? profile.atlasScore, requiredValue: nextStart - 45),
            CurriculumGate(id: "listening", title: "Listening", isPassed: (profile.skillScores[.listening] ?? profile.atlasScore) >= nextStart - 55, currentValue: profile.skillScores[.listening] ?? profile.atlasScore, requiredValue: nextStart - 55)
        ]
    }
}
