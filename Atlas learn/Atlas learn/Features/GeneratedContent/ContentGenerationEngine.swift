//
//  ContentGenerationEngine.swift
//  Atlas learn
//

import Foundation

enum ContentGenerationEngine {
    static func content(for word: WordEntry, userLevel: LearningLevel) -> GeneratedWordContent {
        let fallback = localFallbackContent(for: word, userLevel: userLevel)
        guard fallback.examples.allSatisfy({ ContentValidationEngine.validates(example: $0, targetWord: word.english, level: word.level) }) else {
            return minimalContent(for: word)
        }
        return fallback
    }

    static func localFallbackContent(for word: WordEntry, userLevel: LearningLevel) -> GeneratedWordContent {
        let examples = makeExamples(for: word, userLevel: userLevel)
        let options = WordBank.englishChoices(for: word)
        let translationOptions = WordBank.translationChoices(for: word)
        let collocation = word.collocations.first ?? "use \(word.english)"
        let clozeSentence = examples.first?.english.atlasReplacingWord(word.english, with: "____") ?? word.clozeSentence

        return GeneratedWordContent(
            wordID: word.id,
            version: 1,
            createdAt: Date(),
            usedCount: 0,
            lastUsedAt: nil,
            examples: examples,
            clozeItems: [
                GeneratedClozeItem(sentence: clozeSentence, answer: word.english, options: options)
            ],
            dialogueItems: [
                GeneratedDialogueItem(
                    prompt: "A: I need to talk about \(word.topic.lowercased()).\nB: ...",
                    reply: "Can you use \(word.english) in one clear sentence?",
                    options: [
                        "Can you use \(word.english) in one clear sentence?",
                        "I am \(word.english) yesterday.",
                        "\(word.english) because table.",
                        "No meaning here."
                    ]
                )
            ],
            collocationItems: [
                GeneratedCollocationItem(
                    prompt: "Choose the natural phrase.",
                    correctPhrase: collocation,
                    options: makeCollocationOptions(correct: collocation, word: word)
                )
            ],
            listeningItems: [
                GeneratedListeningItem(
                    audioText: examples.first?.english ?? word.exampleEN,
                    prompt: "Which word did you hear?",
                    answer: word.english,
                    options: options
                )
            ],
            distractors: Array((options + translationOptions).filter { $0 != word.english && $0 != word.russian }.prefix(8)),
            commonMistakes: makeCommonMistakes(for: word)
        )
    }

    private static func minimalContent(for word: WordEntry) -> GeneratedWordContent {
        GeneratedWordContent(
            wordID: word.id,
            version: 1,
            createdAt: Date(),
            usedCount: 0,
            lastUsedAt: nil,
            examples: [
                WordExample(
                    english: word.exampleEN,
                    russian: word.exampleRU,
                    level: word.level,
                    topic: word.topic,
                    source: "local"
                )
            ],
            clozeItems: [
                GeneratedClozeItem(sentence: word.clozeSentence, answer: word.english, options: WordBank.englishChoices(for: word))
            ],
            dialogueItems: [],
            collocationItems: [],
            listeningItems: [],
            distractors: WordBank.englishChoices(for: word).filter { $0 != word.english },
            commonMistakes: []
        )
    }

    private static func makeExamples(for word: WordEntry, userLevel: LearningLevel) -> [WordExample] {
        let base = WordExample(
            english: word.exampleEN,
            russian: word.exampleRU,
            level: word.level,
            topic: word.topic,
            source: "local"
        )
        let extra = zip(word.extraExamplesEN, word.extraExamplesRU).map { english, russian in
            WordExample(english: english, russian: russian, level: word.level, topic: word.topic, source: "local")
        }
        let templates = [
            WordExample(
                english: "I can use \(word.english) in a real situation.",
                russian: "Я могу использовать \(word.english) в реальной ситуации.",
                level: max(word.level, userLevel.order > word.level.order ? word.level : userLevel),
                topic: word.topic,
                source: "template"
            ),
            WordExample(
                english: "The word \(word.english) helps this sentence feel clear.",
                russian: "Слово \(word.english) помогает этому предложению звучать понятно.",
                level: word.level,
                topic: word.topic,
                source: "template"
            ),
            WordExample(
                english: "She remembered \(word.english) during the conversation.",
                russian: "Она вспомнила \(word.english) во время разговора.",
                level: word.level,
                topic: word.topic,
                source: "template"
            )
        ]
        return Array(([base] + extra + templates).prefix(5))
    }

    private static func makeCollocationOptions(correct: String, word: WordEntry) -> [String] {
        var options = [correct]
        if correct.contains("make ") {
            options += [correct.replacingOccurrences(of: "make ", with: "do "), correct.replacingOccurrences(of: "make ", with: "take ")]
        } else {
            options += ["do \(word.english)", "make \(word.english)", "take \(word.english)"]
        }
        return Array(Array(Set(options)).prefix(4))
    }

    private static func makeCommonMistakes(for word: WordEntry) -> [String] {
        var mistakes = [
            "Using \(word.english) as the wrong part of speech.",
            "Forgetting the natural collocation with \(word.english)."
        ]
        if !word.confusionGroup.isEmpty {
            mistakes.append("Confusing \(word.english) with \(word.confusionGroup.joined(separator: ", ")).")
        }
        return mistakes
    }
}

private extension String {
    func atlasReplacingWord(_ targetWord: String, with replacement: String) -> String {
        let escaped = NSRegularExpression.escapedPattern(for: targetWord)
        let pattern = #"(?i)(?<![A-Za-z])"# + escaped + #"(?![A-Za-z])"#
        return replacingOccurrences(of: pattern, with: replacement, options: .regularExpression)
    }
}
