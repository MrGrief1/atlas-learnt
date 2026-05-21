//
//  PracticeGameEngine.swift
//  Atlas learn
//

import Foundation

enum PracticeGameEngine {
    static let templates: [GameTemplate] = [
        GameTemplate(id: "sense", mode: .senseSnap, skills: [.vocabulary], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 10, supportsNewWords: true, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "cloze", mode: .contextCloze, skills: [.vocabulary, .grammar], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 10, supportsNewWords: true, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "collocation", mode: .collocationLock, skills: [.vocabulary, .grammar], minLevel: .a2, maxLevel: .c2, cooldownMinutes: 20, supportsNewWords: false, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "dialogue", mode: .dialogueChoice, skills: [.reading], minLevel: .a2, maxLevel: .c2, cooldownMinutes: 20, supportsNewWords: true, supportsReview: true, supportsWeakWords: false),
        GameTemplate(id: "builder", mode: .wordBuilder, skills: [.vocabulary], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 20, supportsNewWords: true, supportsReview: true, supportsWeakWords: false),
        GameTemplate(id: "audio", mode: .audioCatch, skills: [.listening], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 10, supportsNewWords: false, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "dictation", mode: .dictationSprint, skills: [.listening, .writing], minLevel: .a2, maxLevel: .c2, cooldownMinutes: 30, supportsNewWords: false, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "tiles", mode: .tileTranslation, skills: [.grammar], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 10, supportsNewWords: true, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "grammar", mode: .grammarBridge, skills: [.grammar], minLevel: .a2, maxLevel: .c2, cooldownMinutes: 20, supportsNewWords: false, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "speed", mode: .speedReview, skills: [.vocabulary], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 30, supportsNewWords: false, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "speaking", mode: .speakingEcho, skills: [.speaking], minLevel: .a1, maxLevel: .c2, cooldownMinutes: 45, supportsNewWords: false, supportsReview: true, supportsWeakWords: true),
        GameTemplate(id: "boss", mode: .bossChallenge, skills: [.vocabulary, .grammar, .listening], minLevel: .a2, maxLevel: .c2, cooldownMinutes: 120, supportsNewWords: false, supportsReview: true, supportsWeakWords: true)
    ]

    static func sessionPlan(words: [WordEntry], profile: AtlasProfile) -> PracticeGameSessionPlan {
        let taskCount = targetTaskCount(for: profile.settings.sessionLength)
        var tasks: [GeneratedGameTask] = []
        var usedModes = Set<PracticeMode>()
        var speakingCount = 0

        let selectedWords = words.isEmpty ? Array(WordBank.dailyWords(for: profile).prefix(5)) : words
        guard !selectedWords.isEmpty else {
            return PracticeGameSessionPlan(words: [], tasks: [], sessionLength: profile.settings.sessionLength)
        }

        for (index, word) in selectedWords.enumerated() {
            let mode = firstMode(for: word, profile: profile, usedModes: usedModes)
            tasks.append(task(for: word, mode: mode, profile: profile, seed: index))
            usedModes.insert(mode)
        }

        var cursor = 0
        while tasks.count < taskCount {
            let word = selectedWords[cursor % selectedWords.count]
            let mode = nextMode(for: word, profile: profile, usedModes: usedModes, speakingCount: speakingCount)
            if mode == .speakingEcho { speakingCount += 1 }
            tasks.append(task(for: word, mode: mode, profile: profile, seed: tasks.count * 17 + cursor))
            usedModes.insert(mode)
            cursor += 1
        }

        return PracticeGameSessionPlan(
            words: selectedWords.map(\.id),
            tasks: Array(tasks.prefix(taskCount)),
            sessionLength: profile.settings.sessionLength
        )
    }

    static func task(for word: WordEntry, mode: PracticeMode, profile: AtlasProfile, seed: Int) -> GeneratedGameTask {
        let content = ContentGenerationEngine.content(for: word, userLevel: profile.currentLevel)
        let example = content.examples[safe: seed % max(content.examples.count, 1)] ?? WordExample(english: word.exampleEN, russian: word.exampleRU, level: word.level, topic: word.topic, source: "local")
        let cloze = content.clozeItems.first
        let listening = content.listeningItems.first
        let collocation = content.collocationItems.first
        let dialogue = content.dialogueItems.first

        switch mode {
        case .senseSnap:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .vocabulary,
                level: word.level,
                topic: word.topic,
                prompt: "What does \(word.english) mean here?",
                focusText: example.english,
                detail: word.ipa + " · " + word.partOfSpeech,
                options: WordBank.translationChoices(for: word),
                correctAnswer: word.russian,
                acceptableAnswers: [word.russian],
                errorType: .meaning
            )
        case .contextCloze:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .vocabulary,
                level: word.level,
                topic: word.topic,
                prompt: "Choose the word that completes the context.",
                focusText: cloze?.sentence ?? example.english.atlasReplacingWordForTask(word.english),
                detail: example.russian,
                options: cloze?.options ?? WordBank.clozeChoices(for: word),
                correctAnswer: word.english,
                acceptableAnswers: [word.english],
                errorType: .meaning
            )
        case .collocationLock:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .grammar,
                level: word.level,
                topic: word.topic,
                prompt: collocation?.prompt ?? "Choose the natural phrase.",
                focusText: word.english,
                detail: word.definition(for: profile.appLanguage),
                options: collocation?.options ?? [word.collocations.first ?? "use \(word.english)", "do \(word.english)", "make \(word.english)", "take \(word.english)"],
                correctAnswer: collocation?.correctPhrase ?? word.collocations.first ?? "use \(word.english)",
                acceptableAnswers: [collocation?.correctPhrase ?? word.collocations.first ?? "use \(word.english)"],
                errorType: .collocation
            )
        case .dialogueChoice:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .reading,
                level: word.level,
                topic: word.topic,
                prompt: "Choose the best reply.",
                focusText: dialogue?.prompt ?? "A: I am trying to use \(word.english).\nB: ...",
                detail: word.russian,
                options: dialogue?.options ?? ["Can you say it in context?", "I am \(word.english) yesterday.", "\(word.english) because yes.", "No reply."],
                correctAnswer: dialogue?.reply ?? "Can you say it in context?",
                acceptableAnswers: [dialogue?.reply ?? "Can you say it in context?"],
                errorType: .meaning
            )
        case .wordBuilder:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .vocabulary,
                level: word.level,
                topic: word.topic,
                prompt: "Build the word.",
                focusText: word.russian,
                detail: word.partOfSpeech,
                correctAnswer: word.english,
                acceptableAnswers: [word.english],
                tiles: word.english.chunkedForWordBuilder(seed: seed),
                errorType: .spelling
            )
        case .audioCatch:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .listening,
                level: word.level,
                topic: word.topic,
                prompt: listening?.prompt ?? "Which word did you hear?",
                focusText: "Play",
                detail: example.russian,
                options: listening?.options ?? WordBank.englishChoices(for: word),
                correctAnswer: word.english,
                acceptableAnswers: [word.english],
                audioText: listening?.audioText ?? example.english,
                errorType: .listening
            )
        case .dictationSprint:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .listening,
                level: word.level,
                topic: word.topic,
                prompt: "Listen and type the missing word.",
                focusText: example.english.atlasReplacingWordForTask(word.english),
                detail: example.russian,
                correctAnswer: word.english,
                acceptableAnswers: [word.english],
                audioText: example.english,
                estimatedSeconds: 28,
                errorType: .listening
            )
        case .tileTranslation:
            let answer = example.english.atlasSentenceAnswer
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .grammar,
                level: word.level,
                topic: word.topic,
                prompt: example.russian,
                focusText: word.english,
                detail: "Build the English sentence.",
                correctAnswer: answer,
                acceptableAnswers: [answer],
                tiles: tiles(for: answer, word: word, seed: seed),
                errorType: .wordOrder
            )
        case .grammarBridge:
            let correct = grammarSentence(for: word)
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .grammar,
                level: word.level,
                topic: word.topic,
                prompt: "Choose the correct sentence.",
                focusText: word.english,
                detail: word.russian,
                options: grammarOptions(correct: correct, word: word),
                correctAnswer: correct,
                acceptableAnswers: [correct],
                errorType: .grammar
            )
        case .speedReview:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .vocabulary,
                level: word.level,
                topic: word.topic,
                prompt: "Fast recall.",
                focusText: word.english,
                detail: word.ipa,
                options: WordBank.translationChoices(for: word),
                correctAnswer: word.russian,
                acceptableAnswers: [word.russian],
                estimatedSeconds: 8,
                errorType: .slowRecall
            )
        case .speakingEcho:
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .speaking,
                level: word.level,
                topic: word.topic,
                prompt: "Repeat the word or short phrase.",
                focusText: word.english,
                detail: example.english,
                correctAnswer: word.english,
                acceptableAnswers: [word.english] + word.acceptedAnswers,
                audioText: word.english,
                estimatedSeconds: 28,
                errorType: .pronunciation
            )
        case .bossChallenge:
            let base = task(for: word, mode: profile.settings.listeningEnabled ? .audioCatch : .contextCloze, profile: profile, seed: seed)
            return GeneratedGameTask(
                wordID: base.wordID,
                mode: .bossChallenge,
                skill: base.skill,
                level: base.level,
                topic: base.topic,
                prompt: base.prompt,
                focusText: base.focusText,
                detail: base.detail,
                options: base.options,
                correctAnswer: base.correctAnswer,
                acceptableAnswers: base.acceptableAnswers,
                tiles: base.tiles,
                audioText: base.audioText,
                estimatedSeconds: base.estimatedSeconds,
                isBoss: true,
                errorType: base.errorType
            )
        case .mistakeClinic:
            let sentence = example.english.atlasReplacingWordForTask(word.english)
            return GeneratedGameTask(
                wordID: word.id,
                mode: mode,
                skill: .vocabulary,
                level: word.level,
                topic: word.topic,
                prompt: "Fix the mistake.",
                focusText: sentence,
                detail: "Use \(word.english).",
                correctAnswer: word.english,
                acceptableAnswers: [word.english],
                errorType: .meaning
            )
        default:
            return task(for: word, mode: .senseSnap, profile: profile, seed: seed)
        }
    }

    private static func targetTaskCount(for length: SessionLength) -> Int {
        switch length {
        case .quick: 6
        case .normal: 12
        case .deep: 20
        }
    }

    private static func firstMode(for word: WordEntry, profile: AtlasProfile, usedModes: Set<PracticeMode>) -> PracticeMode {
        let memory = profile.wordProgress[word.id]
        let isNew = memory == nil || memory?.totalAttempts == 0
        if isNew { return .senseSnap }
        if profile.unknownWordIDs.contains(word.id) { return .contextCloze }
        return nextMode(for: word, profile: profile, usedModes: usedModes, speakingCount: 0)
    }

    private static func nextMode(for word: WordEntry, profile: AtlasProfile, usedModes: Set<PracticeMode>, speakingCount: Int) -> PracticeMode {
        let memory = profile.wordProgress[word.id]
        let preferred = preferredModes(for: memory, profile: profile)
        for mode in preferred where isAllowed(mode, profile: profile, usedModes: usedModes, speakingCount: speakingCount) {
            return mode
        }

        let fallback: [PracticeMode] = [.senseSnap, .contextCloze, .tileTranslation, .dialogueChoice, .grammarBridge, .speedReview, .bossChallenge]
        return fallback.first { isAllowed($0, profile: profile, usedModes: usedModes, speakingCount: speakingCount) } ?? .senseSnap
    }

    private static func preferredModes(for memory: WordMemory?, profile: AtlasProfile) -> [PracticeMode] {
        guard let memory else {
            return [.senseSnap, .contextCloze, .tileTranslation]
        }
        let topError = memory.errorTypes.max { $0.value < $1.value }?.key
        switch topError {
        case .meaning:
            return [.senseSnap, .contextCloze, .speedReview]
        case .listening:
            return [.audioCatch, .dictationSprint, .contextCloze]
        case .grammar, .wordOrder:
            return [.grammarBridge, .tileTranslation, .contextCloze]
        case .collocation:
            return [.collocationLock, .contextCloze, .senseSnap]
        case .pronunciation:
            return [.speakingEcho, .audioCatch, .senseSnap]
        case .spelling:
            return [.wordBuilder, .dictationSprint, .contextCloze]
        case .slowRecall:
            return [.speedReview, .senseSnap, .audioCatch]
        case .falseFriend:
            return [.senseSnap, .dialogueChoice, .contextCloze]
        case nil:
            return [.contextCloze, .tileTranslation, .audioCatch, .collocationLock, .dialogueChoice]
        }
    }

    private static func isAllowed(_ mode: PracticeMode, profile: AtlasProfile, usedModes: Set<PracticeMode>, speakingCount: Int) -> Bool {
        if usedModes.contains(mode), profile.settings.gameVariety != .stable { return false }
        if mode.defaultErrorType == .listening && !profile.settings.listeningEnabled { return false }
        if mode.defaultErrorType == .pronunciation && (!profile.settings.speechEnabled || speakingCount >= 2) { return false }
        return true
    }

    private static func tiles(for answer: String, word: WordEntry, seed: Int) -> [String] {
        let base = answer.atlasWords
        let distractors = WordBank.englishChoices(for: word).filter { !base.contains($0) }.prefix(2)
        return WordBank.rotated(base + Array(distractors), seed: seed + WordBank.seed(for: word.id))
    }

    private static func grammarSentence(for word: WordEntry) -> String {
        if word.grammarPatterns.contains(where: { $0.localizedCaseInsensitiveContains("since") }) {
            return "I have known this since Monday."
        }
        if word.partOfSpeech.localizedCaseInsensitiveContains("verb") {
            return "I want to \(word.english) every week."
        }
        return "This is a natural way to use \(word.english)."
    }

    private static func grammarOptions(correct: String, word: WordEntry) -> [String] {
        WordBank.rotated(
            [
                correct,
                correct.replacingOccurrences(of: "have ", with: ""),
                "I am \(word.english) every week.",
                "This use \(word.english) natural."
            ],
            seed: WordBank.seed(for: word.id) + 41
        )
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard !isEmpty else { return nil }
        return self[Swift.max(0, Swift.min(index, count - 1))]
    }
}

private extension String {
    var atlasWords: [String] {
        let pattern = #"[A-Za-z]+(?:'[A-Za-z]+)?|[0-9]+"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return split(separator: " ").map(String.init)
        }
        let range = NSRange(startIndex..., in: self)
        return regex.matches(in: self, range: range).compactMap { match in
            guard let range = Range(match.range, in: self) else { return nil }
            return String(self[range])
        }
    }

    var atlasSentenceAnswer: String {
        atlasWords.joined(separator: " ")
    }

    func atlasReplacingWordForTask(_ targetWord: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: targetWord)
        let pattern = #"(?i)(?<![A-Za-z])"# + escaped + #"(?![A-Za-z])"#
        return replacingOccurrences(of: pattern, with: "____", options: .regularExpression)
    }

    func chunkedForWordBuilder(seed: Int) -> [String] {
        let chars = Array(self)
        guard chars.count > 5 else {
            return WordBank.rotated(chars.map(String.init), seed: seed)
        }
        let midpoint = chars.count / 2
        let chunks = [String(chars[..<midpoint]), String(chars[midpoint...])]
        return WordBank.rotated(chunks, seed: seed)
    }
}
