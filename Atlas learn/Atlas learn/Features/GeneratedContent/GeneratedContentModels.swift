//
//  GeneratedContentModels.swift
//  Atlas learn
//

import Foundation

struct WordExample: Codable, Hashable, Equatable {
    let english: String
    let russian: String
    let level: LearningLevel
    let topic: String
    let source: String
}

struct WordSense: Codable, Hashable, Equatable {
    let id: String
    let definitionEN: String
    let definitionRU: String
    let cefrLevel: LearningLevel
    let examples: [WordExample]
}

struct GeneratedClozeItem: Codable, Equatable, Hashable {
    let sentence: String
    let answer: String
    let options: [String]
}

struct GeneratedDialogueItem: Codable, Equatable, Hashable {
    let prompt: String
    let reply: String
    let options: [String]
}

struct GeneratedCollocationItem: Codable, Equatable, Hashable {
    let prompt: String
    let correctPhrase: String
    let options: [String]
}

struct GeneratedListeningItem: Codable, Equatable, Hashable {
    let audioText: String
    let prompt: String
    let answer: String
    let options: [String]
}

struct GeneratedWordContent: Codable, Equatable {
    let wordID: String
    let version: Int
    let createdAt: Date
    var usedCount: Int
    var lastUsedAt: Date?

    let examples: [WordExample]
    let clozeItems: [GeneratedClozeItem]
    let dialogueItems: [GeneratedDialogueItem]
    let collocationItems: [GeneratedCollocationItem]
    let listeningItems: [GeneratedListeningItem]
    let distractors: [String]
    let commonMistakes: [String]

    func shouldRegenerate(now: Date = Date(), userLevel: LearningLevel, wordLevel: LearningLevel) -> Bool {
        if usedCount >= 3 { return true }
        if now.timeIntervalSince(createdAt) > 7 * 24 * 60 * 60 { return true }
        if userLevel != wordLevel && abs(userLevel.order - wordLevel.order) > 1 { return true }
        return false
    }
}
