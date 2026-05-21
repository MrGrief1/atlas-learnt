//
//  ContentValidationEngine.swift
//  Atlas learn
//

import Foundation

enum ContentValidationEngine {
    static func validates(example: WordExample, targetWord: String, level: LearningLevel) -> Bool {
        appearsExactlyOnce(targetWord, in: example.english) &&
            sentenceFits(example.english, level: level) &&
            containsCyrillic(example.russian) &&
            isClean(example.english) &&
            isClean(example.russian)
    }

    static func validates(options: [String], correctAnswer: String) -> Bool {
        options.count >= 2 &&
            options.filter { normalized($0) == normalized(correctAnswer) }.count == 1 &&
            Set(options.map(normalized)).count == options.count
    }

    static func appearsExactlyOnce(_ targetWord: String, in sentence: String) -> Bool {
        let escaped = NSRegularExpression.escapedPattern(for: targetWord)
        let pattern = #"(?i)(?<![A-Za-z])"# + escaped + #"(?![A-Za-z])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(sentence.startIndex..., in: sentence)
        return regex.numberOfMatches(in: sentence, range: range) == 1
    }

    static func containsCyrillic(_ value: String) -> Bool {
        value.range(of: #"\p{Cyrillic}"#, options: .regularExpression) != nil
    }

    static func sentenceFits(_ sentence: String, level: LearningLevel) -> Bool {
        let wordCount = sentence.split(separator: " ").count
        switch level {
        case .a1:
            return (3...10).contains(wordCount)
        case .a2:
            return (4...12).contains(wordCount)
        case .b1:
            return (5...16).contains(wordCount)
        case .b2:
            return (6...20).contains(wordCount)
        case .c1, .c2:
            return (7...26).contains(wordCount)
        }
    }

    static func isClean(_ value: String) -> Bool {
        let blocked = ["```", "# ", "* ", "\"", "“", "”"]
        guard blocked.allSatisfy({ !value.contains($0) }) else { return false }
        let unsafe = ["kill", "bomb", "cocaine", "suicide"]
        return unsafe.allSatisfy { !value.localizedCaseInsensitiveContains($0) }
    }

    nonisolated private static func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "[^a-zа-яё0-9 ]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
