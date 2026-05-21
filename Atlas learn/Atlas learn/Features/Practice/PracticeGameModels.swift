//
//  PracticeGameModels.swift
//  Atlas learn
//

import Foundation

struct GameTemplate: Identifiable, Codable, Equatable {
    let id: String
    let mode: PracticeMode
    let skills: [PlacementSkill]
    let minLevel: LearningLevel
    let maxLevel: LearningLevel
    let cooldownMinutes: Int
    let supportsNewWords: Bool
    let supportsReview: Bool
    let supportsWeakWords: Bool
}

struct PracticeGameSessionPlan: Codable, Equatable {
    let words: [String]
    let tasks: [GeneratedGameTask]
    let sessionLength: SessionLength
}

extension PracticeMode {
    var expectedSeconds: Int {
        switch self {
        case .speedReview:
            8
        case .bossChallenge:
            18
        case .sentenceCompose, .dictationSprint, .speakingEcho, .speechRepeat:
            28
        default:
            16
        }
    }

    var masteryWeight: Int {
        switch self {
        case .wordReveal:
            3
        case .meaningChoice, .senseSnap, .translateChoice:
            7
        case .contextCloze, .clozeChoice, .clozeWord:
            9
        case .listenChoice, .listenTiles, .audioCatch, .dictationSprint:
            10
        case .sentenceBuilder, .ruToEnglishTiles, .tileTranslation, .wordOrder, .sentenceOrder:
            10
        case .sentenceCompose, .speakingEcho, .speechRepeat:
            12
        case .bossChallenge:
            13
        default:
            8
        }
    }

    var defaultErrorType: ErrorType {
        switch self {
        case .listenChoice, .listenTiles, .audioCatch, .dictationSprint:
            .listening
        case .speechRepeat, .speakingEcho:
            .pronunciation
        case .wordOrder, .sentenceOrder, .sentenceBuilder, .ruToEnglishTiles, .tileTranslation:
            .wordOrder
        case .grammarBridge:
            .grammar
        case .collocationLock:
            .collocation
        case .wordBuilder:
            .spelling
        default:
            .meaning
        }
    }

    var isAtlasScoreBearing: Bool {
        switch self {
        case .bossChallenge, .sentenceCompose, .speakingEcho, .speechRepeat, .dictationSprint, .contextCloze, .grammarBridge:
            true
        default:
            false
        }
    }
}
