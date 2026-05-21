//
//  WordDrillLessonBuilder.swift
//  Atlas learn
//

import Foundation

enum WordDrillLessonBuilder {
    static func build(profile: AtlasProfile, selectedWord: WordEntry?) -> LessonRun {
        let word = selectedWord ?? WordBank.dailyWords(for: profile).first ?? WordBank.placeholder
        let memory = profile.wordProgress[word.id] ?? .fresh

        let types = AdaptiveLessonPlanner.taskTypes(
            for: word,
            profile: profile,
            mode: .wordDrill
        )

        var tasks: [LessonTask] = []

        for (index, type) in types.enumerated() {
            tasks.append(
                LessonTaskFactory.task(
                    type,
                    for: word,
                    seed: index + 1
                )
            )
        }

        if !tasks.contains(where: { $0.type == .finalCheck }) {
            tasks.append(LessonTaskFactory.finalCheckTask(for: word, seed: 99))
        }

        let targetCount: Int
        switch profile.settings.sessionLength {
        case .quick:
            targetCount = 6
        case .normal:
            targetCount = 8
        case .deep:
            targetCount = 12
        }

        while tasks.count < targetCount {
            let type = AdaptiveLessonPlanner.bestNextType(
                for: word,
                profile: profile,
                mode: .wordDrill,
                previousTasks: tasks
            )

            tasks.append(
                LessonTaskFactory.task(
                    type,
                    for: word,
                    seed: tasks.count + 31
                )
            )
        }

        return LessonRun(
            mode: .wordDrill,
            targetWordIDs: [word.id],
            reviewWordIDs: [],
            weakWordIDs: memory.mastery < 45 || memory.wrongCount > 0 ? [word.id] : [],
            tasks: Array(tasks.prefix(targetCount)),
            energy: profile.energy
        )
    }
}
