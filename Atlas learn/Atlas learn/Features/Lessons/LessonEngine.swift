//
//  LessonEngine.swift
//  Atlas learn
//

import Foundation

enum LessonEngine {
    static func makeLesson(
        mode: LessonMode,
        profile: AtlasProfile,
        selectedWord: WordEntry? = nil
    ) -> LessonRun {
        switch mode {
        case .wordDrill:
            return WordDrillLessonBuilder.build(profile: profile, selectedWord: selectedWord)
        case .newWords:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickNewWords(profile: profile, count: targetWordCount(for: profile)), taskTypes: [.introCard, .meaningChoice, .contextChoice, .activeRecallInput, .translationTiles, .finalCheck])
        case .review:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickDueWords(profile: profile, count: targetWordCount(for: profile) + 1), taskTypes: [.meaningChoice, .contextChoice, .audioChoice, .activeRecallInput, .wordOrder, .finalCheck])
        case .weakWords:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickWeakWords(profile: profile, count: targetWordCount(for: profile) + 1), taskTypes: [.activeRecallInput, .mistakeClinic, .contextChoice, .dictation, .dialogueChoice, .finalCheck])
        case .listening:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickDueWords(profile: profile, count: targetWordCount(for: profile) + 1), taskTypes: [.audioChoice, .dictation, .contextChoice, .speechRepeat, .finalCheck])
        case .grammar:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickSessionWords(profile: profile, count: targetWordCount(for: profile) + 1), taskTypes: [.contextChoice, .translationTiles, .wordOrder, .clozeChoice, .sentenceWriting, .finalCheck])
        case .story:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickSessionWords(profile: profile, count: targetWordCount(for: profile)), taskTypes: [.introCard, .dialogueChoice, .contextChoice, .translationTiles, .sentenceWriting, .finalCheck])
        case .boss:
            return buildFocusedLesson(mode: mode, profile: profile, source: pickBossWords(profile: profile, count: targetWordCount(for: profile)), taskTypes: [.activeRecallInput, .audioChoice, .dictation, .sentenceWriting, .finalCheck])
        case .daily:
            return buildDailyLesson(profile: profile)
        }
    }

    static func evaluate(
        answer: LessonAnswer,
        task: LessonTask,
        profile: AtlasProfile
    ) -> LessonEvaluation {
        let language = profile.appLanguage

        if answer.didNotKnow {
            let explanation = task.explanation ?? "Не страшно. Разберём ответ и вернём слово позже."
            return LessonEvaluation(
                isCorrect: false,
                usedHint: true,
                didNotKnow: true,
                xp: 0,
                masteryDelta: 0,
                title: language.text(ru: "Не страшно", en: "No worries"),
                detail: "\(explanation)\n\(language.text(ru: "Правильно:", en: "Correct:")) \(task.correctAnswer)",
                correctAnswer: task.correctAnswer,
                explanation: explanation,
                shouldScheduleMistake: shouldScheduleMistake(for: task)
            )
        }

        let isCorrect = isAccepted(answer.value, task: task, profile: profile)
        let xp = isCorrect ? (answer.usedHint ? max(1, task.xpReward / 2) : task.xpReward) : 0
        let masteryDelta = masteryDelta(for: task, isCorrect: isCorrect, usedHint: answer.usedHint)
        let explanation = task.explanation ?? defaultExplanation(for: task)

        if isCorrect {
            return LessonEvaluation(
                isCorrect: true,
                usedHint: answer.usedHint,
                didNotKnow: false,
                xp: xp,
                masteryDelta: masteryDelta,
                title: language.text(ru: "Верно", en: "Correct"),
                detail: "+\(xp) XP · \(explanation)",
                correctAnswer: task.correctAnswer,
                explanation: explanation,
                shouldScheduleMistake: false
            )
        }

        return LessonEvaluation(
            isCorrect: false,
            usedHint: answer.usedHint,
            didNotKnow: false,
            xp: 0,
            masteryDelta: masteryDelta,
            title: language.text(ru: "Почти", en: "Almost"),
            detail: "\(language.text(ru: "Ты ответил:", en: "You answered:")) \(answer.value)\n\(language.text(ru: "Правильно:", en: "Correct:")) \(task.correctAnswer)\n\(explanation)",
            correctAnswer: task.correctAnswer,
            explanation: explanation,
            shouldScheduleMistake: shouldScheduleMistake(for: task)
        )
    }

    static func nextTask(
        run: LessonRun,
        profile: AtlasProfile
    ) -> LessonTask? {
        run.currentTask
    }

    static func applyResult(
        _ result: LessonTaskResult,
        profile: inout AtlasProfile
    ) {
        let word = result.wordID.flatMap { id in WordBank.all.first { $0.id == id } }
        MasteryEngine.apply(result: result, word: word, profile: &profile)
    }

    static func buildDailyLesson(profile: AtlasProfile) -> LessonRun {
        let targetCount = targetTaskCount(for: profile.settings.sessionLength)
        let newWords = pickNewWords(profile: profile, count: profile.settings.sessionLength == .quick ? 1 : 3)
        let reviewWords = pickDueWords(profile: profile, count: profile.settings.sessionLength == .quick ? 2 : 4)
        let weakWords = pickWeakWords(profile: profile, count: profile.settings.sessionLength == .deep ? 2 : 1)

        var tasks: [LessonTask] = []

        if let review = reviewWords.first {
            tasks.append(LessonTaskFactory.meaningTask(for: review, seed: 1, isWarmup: true))
        }

        if let first = newWords[safe: 0] {
            tasks.append(LessonTaskFactory.introTask(for: first, seed: 2))
            tasks.append(LessonTaskFactory.meaningTask(for: first, seed: 3))
        }

        if let second = newWords[safe: 1] {
            tasks.append(LessonTaskFactory.introTask(for: second, seed: 4))
        }

        if let first = newWords[safe: 0] {
            tasks.append(LessonTaskFactory.contextTask(for: first, seed: 5))
        }

        if let second = newWords[safe: 1] {
            tasks.append(LessonTaskFactory.audioTask(for: second, seed: 6))
        }

        if let third = newWords[safe: 2] {
            tasks.append(LessonTaskFactory.introTask(for: third, seed: 7))
        }

        if let first = newWords[safe: 0] {
            tasks.append(LessonTaskFactory.activeRecallTask(for: first, seed: 8))
        }

        if let third = newWords[safe: 2] ?? newWords.first {
            tasks.append(LessonTaskFactory.tileTask(for: third, seed: 9))
        }

        if let secondReview = reviewWords[safe: 1] ?? weakWords.first {
            tasks.append(LessonTaskFactory.contextTask(for: secondReview, seed: 10))
        }

        if let weak = weakWords.first {
            tasks.append(LessonTaskFactory.dialogueTask(for: weak, seed: 11))
        }

        let finalWords = Array((newWords + weakWords + reviewWords).uniquedByID().prefix(3))
        for (index, word) in finalWords.enumerated() {
            tasks.append(LessonTaskFactory.finalCheckTask(for: word, seed: 20 + index))
        }

        tasks = fillTasks(
            tasks,
            mode: .daily,
            words: (newWords + reviewWords + weakWords).uniquedByID(),
            profile: profile,
            targetCount: targetCount
        )

        return LessonRun(
            mode: .daily,
            targetWordIDs: newWords.map(\.id),
            reviewWordIDs: reviewWords.map(\.id),
            weakWordIDs: weakWords.map(\.id),
            tasks: Array(tasks.prefix(targetCount)),
            energy: profile.energy
        )
    }

    static func targetTaskCount(for length: SessionLength) -> Int {
        switch length {
        case .quick: 6
        case .normal: 12
        case .deep: 18
        }
    }

    static func targetWordCount(for profile: AtlasProfile) -> Int {
        switch profile.settings.sessionLength {
        case .quick: 2
        case .normal: 4
        case .deep: 5
        }
    }

    private static func buildFocusedLesson(
        mode: LessonMode,
        profile: AtlasProfile,
        source: [WordEntry],
        taskTypes: [LessonTaskType]
    ) -> LessonRun {
        let words = source.isEmpty ? pickSessionWords(profile: profile, count: targetWordCount(for: profile)) : source
        let targetCount = targetTaskCount(for: profile.settings.sessionLength)
        var tasks: [LessonTask] = []

        for (index, word) in words.enumerated() {
            let type = taskTypes[index % taskTypes.count]
            if type == .introCard || (profile.wordProgress[word.id]?.totalAttempts ?? 0) == 0 {
                tasks.append(LessonTaskFactory.introTask(for: word, seed: index))
            }
            tasks.append(LessonTaskFactory.task(type, for: word, seed: index + 31))
        }

        tasks = fillTasks(tasks, mode: mode, words: words, profile: profile, targetCount: targetCount)

        let weakIDs = words.filter { profile.weakWordIDs.contains($0.id) }.map(\.id)
        let reviewIDs = words.filter { profile.wordProgress[$0.id]?.isDue() == true }.map(\.id)
        return LessonRun(
            mode: mode,
            targetWordIDs: words.map(\.id),
            reviewWordIDs: reviewIDs,
            weakWordIDs: weakIDs,
            tasks: Array(tasks.prefix(targetCount)),
            energy: profile.energy
        )
    }

    private static func fillTasks(
        _ existing: [LessonTask],
        mode: LessonMode,
        words: [WordEntry],
        profile: AtlasProfile,
        targetCount: Int
    ) -> [LessonTask] {
        var tasks = existing
        let fallbackWords = words.isEmpty ? pickSessionWords(profile: profile, count: 4) : words
        guard !fallbackWords.isEmpty else { return tasks }

        var cursor = 0

        while tasks.count < targetCount {
            let word = fallbackWords[cursor % fallbackWords.count]

            let type = AdaptiveLessonPlanner.bestNextType(
                for: word,
                profile: profile,
                mode: mode,
                previousTasks: tasks
            )

            tasks.append(
                LessonTaskFactory.task(
                    type,
                    for: word,
                    seed: tasks.count + cursor * 13
                )
            )

            cursor += 1
        }

        return tasks
    }

    private static func taskCycle(for mode: LessonMode) -> [LessonTaskType] {
        switch mode {
        case .listening:
            [.audioChoice, .dictation, .contextChoice, .speechRepeat, .activeRecallInput, .finalCheck]
        case .grammar:
            [.contextChoice, .translationTiles, .wordOrder, .clozeChoice, .sentenceWriting, .finalCheck]
        case .story:
            [.dialogueChoice, .contextChoice, .translationTiles, .sentenceWriting, .audioChoice, .finalCheck]
        case .boss:
            [.activeRecallInput, .audioChoice, .dictation, .sentenceWriting, .finalCheck]
        case .weakWords:
            [.activeRecallInput, .mistakeClinic, .contextChoice, .dictation, .dialogueChoice, .finalCheck]
        default:
            [.meaningChoice, .contextChoice, .audioChoice, .translationTiles, .activeRecallInput, .dialogueChoice, .finalCheck]
        }
    }

    private static func nextAllowedType(from cycle: [LessonTaskType], existing: [LessonTask], cursor: Int) -> LessonTaskType {
        for offset in 0..<cycle.count {
            let candidate = cycle[(cursor + offset) % cycle.count]
            if !shouldAvoid(candidate, previous: existing) {
                return candidate
            }
        }
        return cycle[cursor % cycle.count]
    }

    private static func shouldAvoid(_ next: LessonTaskType, previous: [LessonTask]) -> Bool {
        if previous.last?.type == next { return true }
        if previous.suffix(4).filter({ $0.type == next }).count >= 2 { return true }
        return false
    }

    private static func shouldScheduleMistake(for task: LessonTask) -> Bool {
        task.wordID != nil && task.type != .introCard && task.type != .mistakeClinic
    }

    private static func masteryDelta(for task: LessonTask, isCorrect: Bool, usedHint: Bool) -> Int {
        if isCorrect {
            return usedHint ? max(1, task.masteryReward / 2) : task.masteryReward
        }

        switch task.type {
        case .activeRecallInput, .dictation, .sentenceWriting, .speechRepeat, .finalCheck:
            return -2
        default:
            return 0
        }
    }

    private static func isAccepted(_ rawAnswer: String, task: LessonTask, profile: AtlasProfile) -> Bool {
        if task.type == .introCard {
            return true
        }

        let answer = normalized(rawAnswer)
        let accepted = ([task.correctAnswer] + task.acceptedAnswers).map(normalized)
        if accepted.contains(answer) {
            return true
        }

        if task.type == .sentenceWriting {
            return accepted.contains { !($0.isEmpty) && answer.contains($0) }
        }

        guard !profile.settings.strictAnswerChecking else { return false }
        return accepted.contains { option in
            !option.isEmpty && (answer == option || answer.contains(option) || option.contains(answer))
        }
    }

    private static func defaultExplanation(for task: LessonTask) -> String {
        if let context = task.context, !context.isEmpty {
            return context
        }
        return "\(task.correctAnswer) — главный ответ для этого шага."
    }

    nonisolated private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "[^a-zа-яё0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func pickNewWords(profile: AtlasProfile, count: Int) -> [WordEntry] {
        let pack = WordSelectionEngine.dailyPack(for: profile)
        let packed = pack.newWords.compactMap { id in WordBank.all.first { $0.id == id } }
        let fallback = WordBank.all
            .filter { ($0.level == profile.currentLevel || $0.level == profile.currentLevel.next) && (profile.wordProgress[$0.id]?.totalAttempts ?? 0) == 0 }
            .sorted { WordSelectionEngine.priority(for: $0, profile: profile) > WordSelectionEngine.priority(for: $1, profile: profile) }
        return Array((packed + fallback).uniquedByID().prefix(count))
    }

    private static func pickDueWords(profile: AtlasProfile, count: Int) -> [WordEntry] {
        let pack = WordSelectionEngine.dailyPack(for: profile)
        let packed = pack.reviewWords.compactMap { id in WordBank.all.first { $0.id == id } }
        let fallback = WordBank.all
            .filter { profile.wordProgress[$0.id]?.isDue() == true }
            .sorted { WordSelectionEngine.priority(for: $0, profile: profile) > WordSelectionEngine.priority(for: $1, profile: profile) }
        return Array((packed + fallback + WordBank.dailyWords(for: profile)).uniquedByID().prefix(count))
    }

    private static func pickWeakWords(profile: AtlasProfile, count: Int) -> [WordEntry] {
        let pack = WordSelectionEngine.dailyPack(for: profile)
        let packed = pack.weakWords.compactMap { id in WordBank.all.first { $0.id == id } }
        let fallback = profile.weakWordIDs.compactMap { id in WordBank.all.first { $0.id == id } }
        return Array((packed + fallback + WordBank.dailyWords(for: profile)).uniquedByID().prefix(count))
    }

    private static func pickBossWords(profile: AtlasProfile, count: Int) -> [WordEntry] {
        let pack = WordSelectionEngine.dailyPack(for: profile)
        let packed = pack.bossWordIDs.compactMap { id in WordBank.all.first { $0.id == id } }
        return Array((packed + pickWeakWords(profile: profile, count: count) + pickDueWords(profile: profile, count: count)).uniquedByID().prefix(count))
    }

    private static func pickSessionWords(profile: AtlasProfile, count: Int) -> [WordEntry] {
        let words = WordSelectionEngine.wordsForSession(sourceWords: WordBank.dailyWords(for: profile), profile: profile, startWordID: nil)
        return Array((words + WordBank.dailyWords(for: profile)).uniquedByID().prefix(count))
    }
}

enum LessonTaskFactory {
    static func task(_ type: LessonTaskType, for word: WordEntry, seed: Int) -> LessonTask {
        switch type {
        case .introCard:
            introTask(for: word, seed: seed)
        case .meaningChoice:
            meaningTask(for: word, seed: seed)
        case .contextChoice:
            contextTask(for: word, seed: seed)
        case .clozeChoice:
            clozeTask(for: word, seed: seed)
        case .activeRecallInput:
            activeRecallTask(for: word, seed: seed)
        case .translationTiles:
            tileTask(for: word, seed: seed)
        case .wordOrder:
            wordOrderTask(for: word, seed: seed)
        case .audioChoice:
            audioTask(for: word, seed: seed)
        case .dictation:
            dictationTask(for: word, seed: seed)
        case .matchingPairs:
            matchingTask(for: word, seed: seed)
        case .dialogueChoice:
            dialogueTask(for: word, seed: seed)
        case .sentenceWriting:
            sentenceWritingTask(for: word, seed: seed)
        case .speechRepeat:
            speechRepeatTask(for: word, seed: seed)
        case .mistakeClinic:
            LessonTask(
                type: .mistakeClinic,
                wordID: word.id,
                skill: .recall,
                prompt: "Как по-английски: \(word.russian)?",
                context: "\(word.english) = \(word.russian). \(word.definitionRU)",
                correctAnswer: word.english,
                acceptedAnswers: [word.english] + word.acceptedAnswers,
                explanation: "\(word.english) = \(word.russian).",
                difficulty: 2
            )
        case .finalCheck:
            finalCheckTask(for: word, seed: seed)
        }
    }

    static func introTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .introCard,
            wordID: word.id,
            skill: .meaning,
            prompt: word.english,
            context: [
                "\(word.russian) · \(word.partOfSpeech)",
                word.definitionEN,
                word.definitionRU,
                word.exampleEN,
                word.exampleRU
            ].joined(separator: "\n"),
            audioText: word.english,
            correctAnswer: "Понятно",
            acceptedAnswers: ["Понятно", "OK", "Continue"],
            explanation: "\(word.english) = \(word.russian).",
            difficulty: 0
        )
    }

    static func meaningTask(for word: WordEntry, seed: Int, isWarmup: Bool = false) -> LessonTask {
        LessonTask(
            type: .meaningChoice,
            wordID: word.id,
            skill: .meaning,
            prompt: isWarmup ? "Разогрев: что значит \(word.english)?" : "Что значит \(word.english)?",
            context: "\(word.ipa) · \(word.partOfSpeech)",
            options: WordBank.translationChoices(for: word),
            correctAnswer: word.russian,
            acceptedAnswers: [word.russian],
            explanation: "\(word.english) = \(word.russian). \(word.definitionRU)",
            difficulty: isWarmup ? 1 : 2
        )
    }

    static func contextTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .contextChoice,
            wordID: word.id,
            skill: .context,
            prompt: word.clozeSentence,
            context: word.exampleRU,
            options: WordBank.clozeChoices(for: word),
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.exampleEN)\n\(word.exampleRU)",
            difficulty: 2
        )
    }

    static func clozeTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .clozeChoice,
            wordID: word.id,
            skill: .context,
            prompt: word.clozeSentence,
            context: word.definitionRU,
            options: WordBank.clozeChoices(for: word),
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.english) fits because it means \(word.russian).",
            difficulty: 2
        )
    }

    static func activeRecallTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .activeRecallInput,
            wordID: word.id,
            skill: .recall,
            prompt: "Как по-английски: \(word.russian)?",
            context: word.definitionRU,
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.english) = \(word.russian).",
            difficulty: 3
        )
    }

    static func tileTask(for word: WordEntry, seed: Int) -> LessonTask {
        let answer = sentenceAnswer(for: word)
        return LessonTask(
            type: .translationTiles,
            wordID: word.id,
            skill: .grammar,
            prompt: word.exampleRU,
            context: "Собери английскую фразу.",
            options: tiles(for: answer, word: word, seed: seed),
            correctAnswer: answer,
            acceptedAnswers: [answer],
            explanation: word.exampleEN,
            difficulty: 2
        )
    }

    static func wordOrderTask(for word: WordEntry, seed: Int) -> LessonTask {
        let answer = sentenceAnswer(for: word)
        return LessonTask(
            type: .wordOrder,
            wordID: word.id,
            skill: .grammar,
            prompt: "Поставь слова в естественном порядке.",
            context: word.exampleRU,
            options: tiles(for: answer, word: word, seed: seed),
            correctAnswer: answer,
            acceptedAnswers: [answer],
            explanation: word.exampleEN,
            difficulty: 2
        )
    }

    static func audioTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .audioChoice,
            wordID: word.id,
            skill: .listening,
            prompt: "Слушай и выбери слово.",
            context: word.exampleRU,
            audioText: word.english,
            options: WordBank.englishChoices(for: word),
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.english) звучит как \(word.ipa).",
            difficulty: 2
        )
    }

    static func dictationTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .dictation,
            wordID: word.id,
            skill: .spelling,
            prompt: "Слушай фразу и впиши пропущенное слово.",
            context: word.clozeSentence,
            audioText: word.exampleEN,
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: word.exampleEN,
            difficulty: 3
        )
    }

    static func matchingTask(for word: WordEntry, seed: Int) -> LessonTask {
        let nearby = WordBank.translationChoices(for: word).filter { $0 != word.russian }
        let options = WordBank.rotated(["\(word.english) — \(word.russian)"] + nearby.prefix(3).map { "\(word.english) — \($0)" }, seed: seed)
        return LessonTask(
            type: .matchingPairs,
            wordID: word.id,
            skill: .meaning,
            prompt: "Выбери правильную пару.",
            context: word.definitionRU,
            options: options,
            correctAnswer: "\(word.english) — \(word.russian)",
            acceptedAnswers: ["\(word.english) — \(word.russian)"],
            explanation: "\(word.english) = \(word.russian).",
            difficulty: 1
        )
    }

    static func dialogueTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .dialogueChoice,
            wordID: word.id,
            skill: .context,
            prompt: "A: Can you say it shorter?\nB: Yes, I can make it more ____.",
            context: word.russian,
            options: WordBank.clozeChoices(for: word),
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.english) works in dialogue: \(word.definitionEN)",
            difficulty: 2
        )
    }

    static func sentenceWritingTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .sentenceWriting,
            wordID: word.id,
            skill: .writing,
            prompt: word.composePromptRU,
            context: "Используй слово: \(word.english).",
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "Своя фраза засчитывается, если слово использовано по смыслу.",
            difficulty: 4
        )
    }

    static func speechRepeatTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .speechRepeat,
            wordID: word.id,
            skill: .speaking,
            prompt: "Повтори слово или короткую фразу.",
            context: word.exampleEN,
            audioText: word.english,
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.english) · \(word.ipa)",
            difficulty: 3
        )
    }

    static func finalCheckTask(for word: WordEntry, seed: Int) -> LessonTask {
        LessonTask(
            type: .finalCheck,
            wordID: word.id,
            skill: .recall,
            prompt: "Финальная проверка без подсказок: \(word.russian)",
            context: nil,
            correctAnswer: word.english,
            acceptedAnswers: [word.english] + word.acceptedAnswers,
            explanation: "\(word.english) = \(word.russian).",
            difficulty: 4
        )
    }

    static func sentenceAnswer(for word: WordEntry) -> String {
        let source = word.sentenceTiles.isEmpty ? word.exampleEN.atlasLessonWords : word.sentenceTiles
        return source.joined(separator: " ").trimmingCharacters(in: .punctuationCharacters)
    }

    static func tiles(for answer: String, word: WordEntry, seed: Int) -> [String] {
        let base = answer.atlasLessonWords
        let distractors = WordBank.englishChoices(for: word).filter { !base.contains($0) }.prefix(2)
        return WordBank.rotated(base + Array(distractors), seed: seed + WordBank.seed(for: word.id))
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

private extension String {
    var atlasLessonWords: [String] {
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
}
