//
//  MistakeClinicEngine.swift
//  Atlas learn
//

import Foundation

enum MistakeClinicEngine {
    static func makeItem(task: LessonTask, wrongAnswer: String, returnAfterTasks: Int = 2) -> MistakeItem? {
        guard let wordID = task.wordID else { return nil }

        return MistakeItem(
            id: UUID(),
            wordID: wordID,
            originalTaskType: task.type,
            skill: task.skill,
            wrongAnswer: wrongAnswer.isEmpty ? "I don't know" : wrongAnswer,
            correctAnswer: task.correctAnswer,
            explanation: task.explanation ?? explanation(
                wrongAnswer: wrongAnswer,
                correctAnswer: task.correctAnswer,
                fallback: task.context
            ),
            returnAfterTasks: returnAfterTasks
        )
    }

    static func clinicTask(for mistake: MistakeItem, word: WordEntry) -> LessonTask {
        let prompt: String
        let context: String

        switch mistake.skill {
        case .listening:
            prompt = "Слушай ещё раз и впиши слово."
            context = word.exampleEN.replacingOccurrences(of: word.english, with: "____", options: .caseInsensitive)
            return LessonTask(
                type: .mistakeClinic,
                wordID: word.id,
                skill: .listening,
                prompt: prompt,
                context: context,
                audioText: word.exampleEN,
                correctAnswer: word.english,
                acceptedAnswers: [word.english] + word.acceptedAnswers,
                explanation: mistake.explanation,
                difficulty: 2
            )
        case .grammar:
            prompt = "Собери фразу заново."
            let answer = LessonTaskFactory.sentenceAnswer(for: word)
            return LessonTask(
                type: .mistakeClinic,
                wordID: word.id,
                skill: .grammar,
                prompt: prompt,
                context: word.exampleRU,
                options: LessonTaskFactory.tiles(for: answer, word: word, seed: WordBank.seed(for: word.id) + 503),
                correctAnswer: answer,
                acceptedAnswers: [answer],
                explanation: mistake.explanation,
                difficulty: 2
            )
        default:
            prompt = "Как по-английски: \(word.russian)?"
            context = "Разбор: \(mistake.explanation)"
            return LessonTask(
                type: .mistakeClinic,
                wordID: word.id,
                skill: .recall,
                prompt: prompt,
                context: context,
                correctAnswer: word.english,
                acceptedAnswers: [word.english] + word.acceptedAnswers,
                explanation: mistake.explanation,
                difficulty: 2
            )
        }
    }

    static func teachAgainTask(for word: WordEntry) -> LessonTask {
        LessonTaskFactory.introTask(for: word, seed: WordBank.seed(for: word.id) + 701)
    }

    static func explanation(wrongAnswer: String, correctAnswer: String, fallback: String?) -> String {
        let wrong = wrongAnswer.trimmingCharacters(in: .whitespacesAndNewlines)
        if wrong.isEmpty {
            return fallback ?? "Не страшно. Сначала разберём смысл, потом вернём слово в лёгком задании."
        }

        return "Ты выбрал: \(wrong). Правильно: \(correctAnswer). \(fallback ?? "Сравни ответ и попробуй снова в новом формате.")"
    }
}

