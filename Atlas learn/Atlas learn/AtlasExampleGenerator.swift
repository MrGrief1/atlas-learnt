//
//  AtlasExampleGenerator.swift
//  Atlas learn
//

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

struct GeneratedWordExample: Equatable {
    let english: String
    let russian: String
}

enum AtlasExampleGenerator {
    static var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return SystemLanguageModel.default.isAvailable
        }
        #endif

        return false
    }

    static func generateExample(for word: WordEntry) async -> GeneratedWordExample? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await FoundationModelExampleGenerator.generateExample(for: word)
        }
        #endif

        return nil
    }
}

#if canImport(FoundationModels)
@available(iOS 26.0, *)
private enum FoundationModelExampleGenerator {
    static func generateExample(for word: WordEntry) async -> GeneratedWordExample? {
        let model = SystemLanguageModel.default
        guard model.isAvailable else { return nil }

        let session = LanguageModelSession(
            model: model,
            instructions: """
            You write short language-learning examples for an English vocabulary app.
            Return exactly two lines:
            EN: one natural English sentence that uses the target word exactly once.
            RU: a natural Russian translation of that sentence.
            Keep both lines short, concrete, and useful for memorizing the word.
            Do not add explanations, markdown, quotes, or numbering.
            """
        )

        let prompt = """
        Target word: \(word.english)
        Russian meaning: \(word.russian)
        Part of speech: \(word.partOfSpeech)
        CEFR level: \(word.level.tag)
        Topic: \(word.topic)
        Avoid dictionary-style meta sentences. Make a real situation.
        """

        do {
            let response = try await session.respond(
                to: prompt,
                options: GenerationOptions(temperature: 0.72, maximumResponseTokens: 90)
            )
            return parse(response.content, targetWord: word.english)
        } catch {
            return nil
        }
    }

    nonisolated private static func parse(_ text: String, targetWord: String) -> GeneratedWordExample? {
        let lines = text
            .split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let english = value(forPrefix: "EN:", in: lines) ?? lines.first.map(cleanLine)
        let russian = value(forPrefix: "RU:", in: lines) ?? lines.dropFirst().first.map(cleanLine)

        guard
            let english,
            let russian,
            isValidEnglish(english, targetWord: targetWord),
            isValidRussian(russian)
        else {
            return nil
        }

        return GeneratedWordExample(english: english, russian: russian)
    }

    nonisolated private static func value(forPrefix prefix: String, in lines: [String]) -> String? {
        lines
            .first { $0.range(of: prefix, options: [.caseInsensitive, .anchored]) != nil }
            .map { cleanLine(String($0.dropFirst(prefix.count))) }
    }

    nonisolated private static func cleanLine(_ line: String) -> String {
        line
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"“”"))
    }

    nonisolated private static func isValidEnglish(_ sentence: String, targetWord: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: targetWord)
        let pattern = #"(?i)(?<![A-Za-z])"# + escaped + #"(?![A-Za-z])"#
        guard sentence.range(of: pattern, options: .regularExpression) != nil else { return false }
        return sentence.count <= 140 && sentence.split(separator: " ").count >= 4
    }

    nonisolated private static func isValidRussian(_ sentence: String) -> Bool {
        sentence.range(of: #"\p{Cyrillic}"#, options: .regularExpression) != nil && sentence.count <= 160
    }
}
#endif
