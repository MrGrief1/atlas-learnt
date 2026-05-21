//
//  PlacementItemBank.swift
//  Atlas learn
//

import Foundation

enum PlacementItemBank {
    static var all: [PlacementItem] {
        curatedItems + wordContextItems
    }

    private static var wordContextItems: [PlacementItem] {
        WordBank.assessmentWords(startingAt: .b1).prefix(36).map { word in
            PlacementItem(
                id: "vocab-\(word.id)",
                skill: .vocabulary,
                type: .wordMeaning,
                cefrLevel: word.level,
                difficulty: difficulty(for: word.level),
                discrimination: 1.2,
                prompt: "What does \(word.english) mean in this sentence?",
                text: word.exampleEN,
                audioText: nil,
                options: WordBank.translationChoices(for: word),
                correctAnswer: word.russian,
                acceptableAnswers: [word.russian],
                topic: word.topic,
                tags: ["word:\(word.id)", "context"],
                estimatedSeconds: 14
            )
        }
    }

    private static let curatedItems: [PlacementItem] = [
        PlacementItem(
            id: "grammar-since-for-a2",
            skill: .grammar,
            type: .cloze,
            cefrLevel: .a2,
            difficulty: -1.2,
            discrimination: 1.3,
            prompt: "Choose the best word.",
            text: "I have lived here ___ 2021.",
            audioText: nil,
            options: ["since", "for", "from", "during"],
            correctAnswer: "since",
            acceptableAnswers: ["since"],
            topic: "Everyday",
            tags: ["grammar:present-perfect"],
            estimatedSeconds: 15
        ),
        PlacementItem(
            id: "grammar-used-to-b1",
            skill: .grammar,
            type: .sentenceOrder,
            cefrLevel: .b1,
            difficulty: -0.3,
            discrimination: 1.2,
            prompt: "Choose the natural sentence.",
            text: "to / I / used / early / wake up",
            audioText: nil,
            options: ["I used to wake up early.", "I use to wake up early.", "Used I to wake up early.", "I used wake up to early."],
            correctAnswer: "I used to wake up early.",
            acceptableAnswers: ["I used to wake up early"],
            topic: "Everyday",
            tags: ["grammar:used-to"],
            estimatedSeconds: 18
        ),
        PlacementItem(
            id: "grammar-condition-b2",
            skill: .grammar,
            type: .cloze,
            cefrLevel: .b2,
            difficulty: 0.7,
            discrimination: 1.35,
            prompt: "Choose the best form.",
            text: "If I had known about the delay, I ___ earlier.",
            audioText: nil,
            options: ["would have left", "will leave", "would leave", "left"],
            correctAnswer: "would have left",
            acceptableAnswers: ["would have left"],
            topic: "Work",
            tags: ["grammar:conditionals"],
            estimatedSeconds: 20
        ),
        PlacementItem(
            id: "grammar-nuance-c1",
            skill: .grammar,
            type: .cloze,
            cefrLevel: .c1,
            difficulty: 1.65,
            discrimination: 1.4,
            prompt: "Choose the phrase that best preserves the meaning.",
            text: "Hardly ___ the meeting started when the connection failed.",
            audioText: nil,
            options: ["had", "has", "did", "was"],
            correctAnswer: "had",
            acceptableAnswers: ["had"],
            topic: "Work",
            tags: ["grammar:inversion"],
            estimatedSeconds: 22
        ),
        PlacementItem(
            id: "reading-b1-main",
            skill: .reading,
            type: .readingDetail,
            cefrLevel: .b1,
            difficulty: -0.4,
            discrimination: 1.15,
            prompt: "What is the main idea?",
            text: "Marta started using a simple study plan. Every morning, she reviewed five old words and added two new ones. After three weeks, she noticed that short articles felt easier. She still made mistakes, but she could understand the main point faster.",
            audioText: nil,
            options: ["A small routine helped Marta read better.", "Marta stopped learning new words.", "Marta only studied grammar.", "Articles became impossible for Marta."],
            correctAnswer: "A small routine helped Marta read better.",
            acceptableAnswers: ["A small routine helped Marta read better"],
            topic: "Study",
            tags: ["reading:main-idea"],
            estimatedSeconds: 35
        ),
        PlacementItem(
            id: "reading-b2-inference",
            skill: .reading,
            type: .readingInference,
            cefrLevel: .b2,
            difficulty: 0.65,
            discrimination: 1.25,
            prompt: "What can we infer?",
            text: "The team expected the client to reject the first version. Instead, the client asked only for minor changes and praised the structure. The designer looked relieved, but the developer opened a new document and started listing hidden risks.",
            audioText: nil,
            options: ["The developer still sees possible problems.", "The client hated the structure.", "The designer wanted more changes.", "The team has finished all work."],
            correctAnswer: "The developer still sees possible problems.",
            acceptableAnswers: ["The developer still sees possible problems"],
            topic: "Work",
            tags: ["reading:inference"],
            estimatedSeconds: 42
        ),
        PlacementItem(
            id: "reading-c1-context",
            skill: .reading,
            type: .readingInference,
            cefrLevel: .c1,
            difficulty: 1.55,
            discrimination: 1.35,
            prompt: "What does the writer imply?",
            text: "The proposal was not rejected outright. It was praised for ambition, then returned with a request for 'a more realistic timeline', which everyone in the room understood as a polite warning.",
            audioText: nil,
            options: ["The timeline was probably too optimistic.", "The proposal was accepted without changes.", "Nobody understood the warning.", "The proposal lacked ambition."],
            correctAnswer: "The timeline was probably too optimistic.",
            acceptableAnswers: ["The timeline was probably too optimistic"],
            topic: "Business",
            tags: ["reading:implication"],
            estimatedSeconds: 45
        ),
        PlacementItem(
            id: "listening-a2-choice",
            skill: .listening,
            type: .listeningChoice,
            cefrLevel: .a2,
            difficulty: -1.35,
            discrimination: 1.1,
            prompt: "Listen and choose what the speaker decided.",
            text: nil,
            audioText: "I will take the train because the bus is late.",
            options: ["Take the train", "Wait for the bus", "Call a taxi", "Walk home"],
            correctAnswer: "Take the train",
            acceptableAnswers: ["Take the train"],
            topic: "Travel",
            tags: ["listening:decision"],
            estimatedSeconds: 24
        ),
        PlacementItem(
            id: "listening-b1-word",
            skill: .listening,
            type: .listeningChoice,
            cefrLevel: .b1,
            difficulty: -0.25,
            discrimination: 1.25,
            prompt: "Which word did you hear?",
            text: nil,
            audioText: "The answer was concise.",
            options: ["concise", "consist", "conscious", "constant"],
            correctAnswer: "concise",
            acceptableAnswers: ["concise"],
            topic: "Work",
            tags: ["word:concise", "listening:minimal"],
            estimatedSeconds: 20
        ),
        PlacementItem(
            id: "dictation-b1",
            skill: .listening,
            type: .dictation,
            cefrLevel: .b1,
            difficulty: -0.1,
            discrimination: 1.2,
            prompt: "Listen and type the missing word.",
            text: "The answer was ____.",
            audioText: "The answer was concise.",
            options: [],
            correctAnswer: "concise",
            acceptableAnswers: ["concise"],
            topic: "Work",
            tags: ["word:concise", "dictation"],
            estimatedSeconds: 28
        ),
        PlacementItem(
            id: "writing-b1-however",
            skill: .writing,
            type: .shortWriting,
            cefrLevel: .b1,
            difficulty: -0.15,
            discrimination: 0.9,
            prompt: "Write one sentence with however.",
            text: nil,
            audioText: nil,
            options: [],
            correctAnswer: "however",
            acceptableAnswers: ["however"],
            topic: "Study",
            tags: ["writing:connector"],
            estimatedSeconds: 45
        ),
        PlacementItem(
            id: "writing-b2-although",
            skill: .writing,
            type: .shortWriting,
            cefrLevel: .b2,
            difficulty: 0.85,
            discrimination: 0.95,
            prompt: "Write one sentence with although.",
            text: nil,
            audioText: nil,
            options: [],
            correctAnswer: "although",
            acceptableAnswers: ["although"],
            topic: "Work",
            tags: ["writing:contrast"],
            estimatedSeconds: 50
        )
    ]

    private static func difficulty(for level: LearningLevel) -> Double {
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
