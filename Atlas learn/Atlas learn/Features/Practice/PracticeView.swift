//
//  PracticeView.swift
//  Atlas learn
//

import SwiftUI

struct PracticeView: View {
    @Binding var profile: AtlasProfile
    let words: [WordEntry]
    var startWordID: WordEntry.ID?

    private var selectedWord: WordEntry? {
        if let startWordID {
            return words.first { $0.id == startWordID } ?? WordBank.all.first { $0.id == startWordID }
        }

        return words.count == 1 ? words.first : nil
    }

    private var mode: LessonMode {
        words.count == 1 && selectedWord != nil ? .wordDrill : .daily
    }

    var body: some View {
        LessonPlayerView(
            profile: $profile,
            mode: mode,
            selectedWord: selectedWord
        )
    }
}

