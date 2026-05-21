//
//  GeneratedGameTask.swift
//  Atlas learn
//

import Foundation

struct GeneratedGameTask: Codable, Equatable, Identifiable {
    let id: UUID
    let wordID: String
    let mode: PracticeMode
    let skill: PlacementSkill
    let level: LearningLevel
    let topic: String
    let prompt: String
    let focusText: String
    let detail: String
    let options: [String]
    let correctAnswer: String
    let acceptableAnswers: [String]
    let tiles: [String]
    let audioText: String?
    let estimatedSeconds: Int
    let isBoss: Bool
    let isRepair: Bool
    let errorType: ErrorType?

    init(
        id: UUID = UUID(),
        wordID: String,
        mode: PracticeMode,
        skill: PlacementSkill,
        level: LearningLevel,
        topic: String,
        prompt: String,
        focusText: String,
        detail: String,
        options: [String] = [],
        correctAnswer: String,
        acceptableAnswers: [String] = [],
        tiles: [String] = [],
        audioText: String? = nil,
        estimatedSeconds: Int = 18,
        isBoss: Bool = false,
        isRepair: Bool = false,
        errorType: ErrorType? = nil
    ) {
        self.id = id
        self.wordID = wordID
        self.mode = mode
        self.skill = skill
        self.level = level
        self.topic = topic
        self.prompt = prompt
        self.focusText = focusText
        self.detail = detail
        self.options = options
        self.correctAnswer = correctAnswer
        self.acceptableAnswers = acceptableAnswers
        self.tiles = tiles
        self.audioText = audioText
        self.estimatedSeconds = estimatedSeconds
        self.isBoss = isBoss
        self.isRepair = isRepair
        self.errorType = errorType
    }

    nonisolated var closestStep: PracticeStep {
        switch mode {
        case .senseSnap, .contextCloze, .collocationLock, .dialogueChoice, .audioCatch, .grammarBridge, .memoryPairs, .speedReview, .bossChallenge, .translateChoice, .synonymMatch, .listenChoice, .clozeChoice, .clozeWord, .meaningChoice:
            return mode == .contextCloze || mode == .clozeChoice ? .clozeWord : .meaningChoice
        case .wordBuilder, .tileTranslation, .sentenceBuilder, .ruToEnglishTiles:
            return .ruToEnglishTiles
        case .dictationSprint, .sentenceCompose:
            return .clozeWord
        case .wordReveal:
            return .meaningChoice
        case .sentenceOrder, .wordOrder:
            return .wordOrder
        case .speakingEcho, .speechRepeat:
            return .speechRepeat
        case .listenTiles:
            return .listenTiles
        case .mistakeClinic:
            return .clozeWord
        }
    }

    var isChoiceTask: Bool {
        !options.isEmpty && !isTextInputTask && closestStep != .speechRepeat
    }

    var isTileTask: Bool {
        !tiles.isEmpty && [.ruToEnglishTiles, .listenTiles, .wordOrder].contains(closestStep)
    }

    var isTextInputTask: Bool {
        switch mode {
        case .dictationSprint, .sentenceCompose, .mistakeClinic:
            return true
        default:
            return options.isEmpty && tiles.isEmpty && closestStep != .speechRepeat
        }
    }

    var requiredTileCount: Int {
        correctAnswer
            .split(separator: " ")
            .count
    }

    func repairVariant() -> GeneratedGameTask {
        GeneratedGameTask(
            wordID: wordID,
            mode: .mistakeClinic,
            skill: skill,
            level: level,
            topic: topic,
            prompt: prompt,
            focusText: focusText,
            detail: detail,
            options: options,
            correctAnswer: correctAnswer,
            acceptableAnswers: acceptableAnswers,
            tiles: tiles,
            audioText: audioText,
            estimatedSeconds: estimatedSeconds,
            isBoss: false,
            isRepair: true,
            errorType: errorType
        )
    }
}
