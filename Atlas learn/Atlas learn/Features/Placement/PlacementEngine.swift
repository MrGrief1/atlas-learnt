//
//  PlacementEngine.swift
//  Atlas learn
//

import Foundation

struct PlacementEngine: Equatable {
    private(set) var theta: Double
    private(set) var attempt: PlacementAttempt
    private(set) var askedItemIDs: Set<String> = []
    private(set) var dangerousGapItemIDs: Set<String> = []

    let itemBank: [PlacementItem]
    let learningRate: Double

    init(
        selectedStartLevel: LearningLevel,
        selfEstimate: PlacementSelfEstimate,
        itemBank: [PlacementItem] = PlacementItemBank.all,
        learningRate: Double = 0.75
    ) {
        self.theta = Self.initialTheta(for: selectedStartLevel) + selfEstimate.thetaAdjustment
        self.attempt = PlacementAttempt(selectedStartLevel: selectedStartLevel)
        self.itemBank = itemBank
        self.learningRate = learningRate
    }

    var currentItem: PlacementItem? {
        nextItem()
    }

    var answeredCount: Int {
        attempt.answers.count
    }

    var confidence: Double {
        guard answeredCount > 0 else { return 0.18 }
        let recent = attempt.answers.suffix(8)
        let meanScore = recent.map(\.score).reduce(0, +) / Double(max(recent.count, 1))
        let consistency = 1.0 - min(1.0, abs(meanScore - 0.5) * 0.8)
        let availableSkills = Set(itemBank.map(\.skill))
        let coverage = Double(Set(attempt.answers.map(\.skill)).count) / Double(max(availableSkills.count, 1))
        let lengthFactor = min(1.0, Double(answeredCount) / 32.0)
        let stability = levelStableInRecentAnswers ? 0.18 : 0
        return min(0.96, 0.18 + lengthFactor * 0.34 + coverage * 0.22 + (1 - consistency) * 0.10 + stability)
    }

    var shouldStop: Bool {
        if answeredCount >= 45 { return true }
        if answeredCount >= 24 && confidence >= 0.82 { return true }
        if answeredCount >= 30 && levelStableInRecentAnswers { return true }
        return false
    }

    mutating func record(answer: String, for item: PlacementItem, timeSpent: TimeInterval, confidence answerConfidence: AnswerConfidence) {
        var actual = score(answer: answer, item: item)
        if actual >= 1.0 && timeSpent > Double(item.estimatedSeconds) * 1.8 {
            actual = 0.75
        }
        if actual >= 1.0 && answerConfidence == .hard {
            actual = 0.7
        }
        if actual == 0 && answerConfidence == .easy {
            dangerousGapItemIDs.insert(item.id)
        }

        let p = 1 / (1 + exp(-item.discrimination * (theta - item.difficulty)))
        let delta = learningRate * item.discrimination * (actual - p)
        theta += min(max(delta, -0.35), 0.35)
        theta = min(max(theta, -3.0), 3.0)

        let placementAnswer = PlacementAnswer(
            item: item,
            answer: answer,
            score: actual,
            timeSpent: timeSpent,
            confidence: answerConfidence
        )
        attempt.answers.append(placementAnswer)
        askedItemIDs.insert(item.id)
    }

    mutating func finish(early: Bool = false, dailyGoal: Int, selectedTopics: [String]) -> PlacementResult {
        let result = makeResult(early: early, dailyGoal: dailyGoal, selectedTopics: selectedTopics)
        attempt.finishedAt = Date()
        attempt.result = result
        return result
    }

    private func nextItem() -> PlacementItem? {
        itemBank
            .filter { !askedItemIDs.contains($0.id) }
            .sorted { scoreForSelection($0) < scoreForSelection($1) }
            .first
    }

    private func scoreForSelection(_ item: PlacementItem) -> Double {
        let skillPenalty = streakCount(for: item.skill, in: attempt.answers.suffix(3).map(\.skill)) >= 3 ? 2.4 : 0
        let repeatedTopicPenalty = streakCount(for: item.topic, in: attempt.answers.suffix(2).compactMap { answer in
            itemBank.first { $0.id == answer.itemID }?.topic
        }) >= 2 ? 1.6 : 0
        let repeatedTypePenalty = attempt.answers.last?.type == item.type ? 1.8 : 0
        let neededSkillBoost = needsMoreCoverage(item.skill) ? 0.8 : 0
        return abs(item.difficulty - theta) + skillPenalty + repeatedTopicPenalty + repeatedTypePenalty - neededSkillBoost
    }

    private func needsMoreCoverage(_ skill: PlacementSkill) -> Bool {
        let counts = Dictionary(grouping: attempt.answers, by: \.skill).mapValues(\.count)
        let minimum = counts.values.min() ?? 0
        return (counts[skill] ?? 0) <= minimum
    }

    private func score(answer: String, item: PlacementItem) -> Double {
        if answer == PlacementAnswerValue.unknownWord {
            return 0
        }

        let normalizedAnswer = normalized(answer)
        let acceptable = ([item.correctAnswer] + item.acceptableAnswers).map(normalized)

        if item.type == .shortWriting {
            let words = normalizedAnswer.split(separator: " ")
            guard words.count >= 5 else { return 0 }
            return acceptable.contains { normalizedAnswer.contains($0) } ? 1 : 0.35
        }

        if item.type == .dictation {
            return acceptable.contains(normalizedAnswer) ? 1 : (acceptable.contains { normalizedAnswer.contains($0) } ? 0.5 : 0)
        }

        return acceptable.contains(normalizedAnswer) ? 1 : 0
    }

    private func makeResult(early: Bool, dailyGoal: Int, selectedTopics: [String]) -> PlacementResult {
        let atlasScore = LearningLevel.atlasScore(fromTheta: theta)
        let level = LearningLevel.from(atlasScore: atlasScore)
        let skillScores = makeSkillScores(defaultScore: atlasScore)
        let answeredSkills = Set(attempt.answers.map(\.skill))
        let sortedSkills = skillScores
            .filter { answeredSkills.contains($0.key) }
            .sorted { $0.value < $1.value }
        let weakSkills = sortedSkills
            .filter { $0.value < atlasScore }
            .prefix(2)
            .map(\.key)
        let strongSkills = sortedSkills
            .reversed()
            .filter { $0.value > atlasScore }
            .prefix(2)
            .map(\.key)
        let wrongWordIDs = attempt.answers
            .filter { $0.score < 0.75 }
            .compactMap(\.wordID)
        let unknown = Array(Set(wrongWordIDs)).sorted()
        let resultConfidence = max(0.2, confidence - (early ? 0.22 : 0))

        return PlacementResult(
            cefrLevel: level,
            atlasScore: atlasScore,
            confidence: resultConfidence,
            skillScores: skillScores,
            weakSkills: weakSkills,
            strongSkills: strongSkills,
            unknownWordIDs: unknown,
            recommendedTopics: selectedTopics.isEmpty ? ["Everyday", "Work", "Study"] : selectedTopics,
            recommendedDailyGoal: dailyGoal,
            createdAt: Date()
        )
    }

    private func makeSkillScores(defaultScore: Int) -> [PlacementSkill: Int] {
        var result: [PlacementSkill: Int] = [:]
        for skill in PlacementSkill.allCases {
            let answers = attempt.answers.filter { $0.skill == skill }
            guard !answers.isEmpty else {
                result[skill] = defaultScore
                continue
            }
            let average = answers.map(\.score).reduce(0, +) / Double(answers.count)
            let offset = Int(((average - 0.5) * 120).rounded())
            result[skill] = min(600, max(0, defaultScore + offset))
        }
        return result
    }

    private var levelStableInRecentAnswers: Bool {
        guard attempt.answers.count >= 8 else { return false }
        let current = LearningLevel.from(atlasScore: LearningLevel.atlasScore(fromTheta: theta))
        let recentAccuracy = attempt.answers.suffix(8).map(\.score).reduce(0, +) / 8
        return (0.38...0.82).contains(recentAccuracy) && current == LearningLevel.from(atlasScore: LearningLevel.atlasScore(fromTheta: theta))
    }

    private func streakCount<T: Equatable>(for value: T, in values: [T]) -> Int {
        values.reversed().prefix { $0 == value }.count
    }

    private func normalized(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "[^a-zа-яё0-9 ]", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func initialTheta(for level: LearningLevel) -> Double {
        switch level {
        case .a1: -2.5
        case .a2: -1.5
        case .b1: -0.5
        case .b2: 0.5
        case .c1: 1.5
        case .c2: 2.5
        }
    }
}
