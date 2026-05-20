//
//  WordBankView.swift
//  Atlas learn
//

import SwiftUI

enum WordBankFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case unknown
    case weak
    case mastered

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .all: language.text(ru: "Все", en: "All")
        case .saved: language.text(ru: "Сохраненные", en: "Saved")
        case .unknown: language.text(ru: "Повторить", en: "Review")
        case .weak: language.text(ru: "Слабые", en: "Weak")
        case .mastered: language.text(ru: "Освоено", en: "Mastered")
        }
    }
}

struct WordBankView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile

    @State private var searchText = ""
    @State private var filter: WordBankFilter = .all
    @State private var levelFilter: LearningLevel?
    @State private var topicFilter: String?

    private var language: AppLanguage {
        profile.appLanguage
    }

    private var filteredWords: [WordEntry] {
        WordBank.all.filter { word in
            let matchesFilter: Bool

            switch filter {
            case .all:
                matchesFilter = true
            case .saved:
                matchesFilter = profile.savedWordIDs.contains(word.id)
            case .unknown:
                matchesFilter = profile.unknownWordIDs.contains(word.id)
            case .weak:
                matchesFilter = profile.weakWordIDs.contains(word.id)
            case .mastered:
                matchesFilter = (profile.wordProgress[word.id]?.mastery ?? 0) >= 70
            }

            guard matchesFilter else { return false }
            if let levelFilter, word.level != levelFilter { return false }
            if let topicFilter, word.topic != topicFilter { return false }

            if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }

            let query = searchText.lowercased()
            return word.english.lowercased().contains(query) || word.russian.lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack {
            AtlasColors.paper
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(language.text(ru: "Банк слов", en: "Word bank"))
                        .font(.system(size: 34, weight: .black, design: .serif))

                    Spacer()

                    Button {
                        AtlasHaptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .black))
                            .foregroundStyle(.black)
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(.white))
                            .overlay(Circle().stroke(.black, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black.opacity(0.56))

                    TextField(language.text(ru: "Найти слово", en: "Search words"), text: $searchText)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .textInputAutocapitalization(.never)
                }
                .padding(.horizontal, 16)
                .frame(height: 48)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(.black, lineWidth: 2)
                )

                AtlasSegmentedPicker(
                    options: WordBankFilter.allCases,
                    selection: $filter
                ) { filter in
                    filter.title(for: language)
                }

                filterChips

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredWords) { word in
                            WordBankRow(word: word, profile: $profile)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.horizontal, AtlasLayout.scrollShadowPadding)
                    .padding(.top, AtlasLayout.scrollTopInset)
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, AtlasLayout.modalPadding - AtlasLayout.scrollShadowPadding)
            .padding(.top, 20)
        }
        .atlasMotion(filter)
        .atlasSoftMotion(searchText)
        .atlasSoftMotion(profile)
    }

    private var filterChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(
                        title: language.text(ru: "Все уровни", en: "All levels"),
                        isSelected: levelFilter == nil
                    ) {
                        levelFilter = nil
                    }

                    ForEach(LearningLevel.allCases) { level in
                        chip(title: level.tag, isSelected: levelFilter == level) {
                            levelFilter = level
                        }
                    }
                }
                .padding(.horizontal, 1)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(
                        title: language.text(ru: "Все темы", en: "All topics"),
                        isSelected: topicFilter == nil
                    ) {
                        topicFilter = nil
                    }

                    ForEach(WordBank.topics, id: \.self) { topic in
                        chip(title: WordBank.topicTitle(topic, for: language), isSelected: topicFilter == topic) {
                            topicFilter = topic
                        }
                    }
                }
                .padding(.horizontal, 1)
            }
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            AtlasHaptics.selection()
            withAnimation(.atlasSpring) {
                action()
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundStyle(isSelected ? .white : .black)
                .padding(.horizontal, 12)
                .frame(height: 34)
                .background(Capsule().fill(isSelected ? AtlasColors.ink : .white))
                .overlay(Capsule().stroke(AtlasColors.line, lineWidth: 1.6))
        }
        .buttonStyle(.plain)
    }
}

struct WordBankRow: View {
    let word: WordEntry
    @Binding var profile: AtlasProfile

    private var language: AppLanguage {
        profile.appLanguage
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 8) {
                    Text(word.english)
                        .font(.system(size: 20, weight: .black, design: .serif))

                    Text(word.level.tag)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AtlasColors.mint.opacity(0.6)))

                    Text("\(profile.wordProgress[word.id]?.mastery ?? 0)%")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.06)))
                }

                Text(word.russian)
                    .font(.system(size: 15, weight: .black, design: .rounded))

                Text(word.definition(for: language))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    AtlasHaptics.tap()
                    AtlasSpeech.speak(word.english, voice: profile.selectedSpeechVoice)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 18, weight: .bold))
                }

                Button {
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        profile.toggleSaved(word.id)
                    }
                } label: {
                    Image(systemName: profile.savedWordIDs.contains(word.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 19, weight: .bold))
                }

                Button {
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        profile.toggleFavorite(word.id)
                    }
                } label: {
                    Image(systemName: profile.favoriteWordIDs.contains(word.id) ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .bold))
                }
            }
            .foregroundStyle(.black)
            .buttonStyle(.plain)
        }
        .padding(15)
        .foregroundStyle(.black)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 21, style: .continuous)
                .stroke(.black.opacity(0.72), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.65), radius: 0, y: 4)
        .atlasMotion(profile.savedWordIDs.contains(word.id))
        .atlasMotion(profile.favoriteWordIDs.contains(word.id))
        .atlasSoftMotion(language)
    }
}
