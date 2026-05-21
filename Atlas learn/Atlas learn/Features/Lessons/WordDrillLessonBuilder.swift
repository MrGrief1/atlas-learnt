//
//  WordDrillLessonBuilder.swift
//  Atlas learn
//

import Foundation

enum WordDrillLessonBuilder {
    static func build(profile: AtlasProfile, selectedWord: WordEntry?) -> LessonRun {
        let word = selectedWord ?? WordBank.dailyWords(for: profile).first ?? WordBank.all[0]
        let memory = profile.wordProgress[word.id]
        let isWeak = profile.unknownWordIDs.contains(word.id) ||
            (memory?.wrongCount ?? 0) > 0 ||
            ((memory?.totalAttempts ?? 0) > 0 && (memory?.mastery ?? 0) < 45)

        let tasks: [LessonTask]
        if isWeak {
            tasks = [
                LessonTaskFactory.activeRecallTask(for: word, seed: 1),
                LessonTaskFactory.contextTask(for: word, seed: 2),
                LessonTaskFactory.task(.mistakeClinic, for: word, seed: 3),
                LessonTaskFactory.dictationTask(for: word, seed: 4),
                LessonTaskFactory.finalCheckTask(for: word, seed: 5)
            ]
        } else {
            tasks = [
                LessonTaskFactory.introTask(for: word, seed: 1),
                LessonTaskFactory.meaningTask(for: word, seed: 2),
                LessonTaskFactory.contextTask(for: word, seed: 3),
                LessonTaskFactory.audioTask(for: word, seed: 4),
                LessonTaskFactory.activeRecallTask(for: word, seed: 5),
                LessonTaskFactory.clozeTask(for: word, seed: 6),
                LessonTaskFactory.sentenceWritingTask(for: word, seed: 7),
                LessonTaskFactory.finalCheckTask(for: word, seed: 8)
            ]
        }

        return LessonRun(
            mode: .wordDrill,
            targetWordIDs: [word.id],
            reviewWordIDs: [],
            weakWordIDs: isWeak ? [word.id] : [],
            tasks: tasks,
            energy: profile.energy
        )
    }
}

