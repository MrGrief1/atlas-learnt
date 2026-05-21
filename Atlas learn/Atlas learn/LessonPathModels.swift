//
//  LessonPathModels.swift
//  Atlas learn
//

import Foundation

struct LessonPathUnit: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let nodes: [LessonPathNode]
}

struct LessonPathNode: Identifiable, Equatable {
    enum State: Equatable {
        case completed
        case current
        case locked
    }

    let id: String
    let title: String
    let mode: LessonMode
    let state: State
    let estimatedMinutes: Int
}

enum LessonPathCatalog {
    static func units(for profile: AtlasProfile) -> [LessonPathUnit] {
        [
            LessonPathUnit(
                id: "everyday-basics",
                title: "Unit 1: Everyday Basics",
                subtitle: "Новые слова, контекст, слух и проверка.",
                nodes: [
                    LessonPathNode(id: "u1-new", title: "New words", mode: .newWords, state: .completed, estimatedMinutes: 4),
                    LessonPathNode(id: "u1-practice", title: "Practice", mode: .daily, state: .current, estimatedMinutes: 5),
                    LessonPathNode(id: "u1-listening", title: "Listening", mode: .listening, state: profile.xp > 40 ? .current : .locked, estimatedMinutes: 5),
                    LessonPathNode(id: "u1-story", title: "Story", mode: .story, state: profile.xp > 80 ? .current : .locked, estimatedMinutes: 6),
                    LessonPathNode(id: "u1-review", title: "Review", mode: .review, state: profile.dueWordsCount > 0 ? .current : .locked, estimatedMinutes: 5),
                    LessonPathNode(id: "u1-boss", title: "Boss Check", mode: .boss, state: profile.xp > 120 ? .current : .locked, estimatedMinutes: 7)
                ]
            ),
            LessonPathUnit(
                id: "work-study",
                title: "Unit 2: Work & Study",
                subtitle: "Фразы для задач, учёбы и ясных ответов.",
                nodes: [
                    LessonPathNode(id: "u2-new", title: "New words", mode: .newWords, state: .locked, estimatedMinutes: 5),
                    LessonPathNode(id: "u2-grammar", title: "Grammar", mode: .grammar, state: .locked, estimatedMinutes: 6),
                    LessonPathNode(id: "u2-review", title: "Review", mode: .review, state: .locked, estimatedMinutes: 5),
                    LessonPathNode(id: "u2-boss", title: "Boss Check", mode: .boss, state: .locked, estimatedMinutes: 7)
                ]
            )
        ]
    }
}

