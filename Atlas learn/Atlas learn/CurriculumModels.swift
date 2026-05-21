//
//  CurriculumModels.swift
//  Atlas learn
//

import Foundation

struct LearningSublevel: Codable, Equatable, Identifiable, Hashable {
    let level: LearningLevel
    let index: Int

    var id: String { tag }
    var tag: String { "\(level.tag).\(index)" }
}

struct CurriculumGate: Codable, Equatable, Identifiable {
    let id: String
    let title: String
    let isPassed: Bool
    let currentValue: Int
    let requiredValue: Int
}

struct CurriculumSnapshot: Codable, Equatable {
    var cefrLevel: LearningLevel
    var sublevel: LearningSublevel
    var atlasScore: Int
    var skillGaps: [PlacementSkill]
    var recommendedPathTitle: String
    var gates: [CurriculumGate]
}
