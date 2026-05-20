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

private enum WordBankPickerKind: Hashable {
    case level
    case topic
}

struct WordBankView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile

    @State private var searchText = ""
    @State private var filter: WordBankFilter = .all
    @State private var levelFilter: LearningLevel?
    @State private var topicFilter: String?
    @State private var expandedPicker: WordBankPickerKind?

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

                filterControls

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
            .foregroundStyle(.black)
        }
        .atlasMotion(filter)
        .atlasSoftMotion(searchText)
        .atlasSoftMotion(profile)
    }

    private var filterControls: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                filterSelector(
                    kind: .level,
                    icon: "slider.horizontal.3",
                    title: language.text(ru: "Уровень", en: "Level"),
                    value: levelFilter?.tag ?? language.text(ru: "Все", en: "All")
                )

                filterSelector(
                    kind: .topic,
                    icon: "square.grid.2x2",
                    title: language.text(ru: "Тема", en: "Topic"),
                    value: topicFilter.map { WordBank.topicTitle($0, for: language) } ?? language.text(ru: "Все", en: "All")
                )

                Button {
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        levelFilter = nil
                        topicFilter = nil
                        expandedPicker = nil
                    }
                } label: {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 17, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 48, height: 54)
                        .background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AtlasColors.line, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
                .disabled(levelFilter == nil && topicFilter == nil)
                .opacity(levelFilter == nil && topicFilter == nil ? 0.45 : 1)
            }

            if let expandedPicker {
                customPicker(for: expandedPicker)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }

            HStack {
                Text(language.text(ru: "Найдено", en: "Showing"))
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.56))

                Text("\(filteredWords.count)")
                    .font(.system(size: 14, weight: .black, design: .rounded))

                Spacer()

                if levelFilter != nil || topicFilter != nil {
                    Text(language.text(ru: "Фильтр включен", en: "Filtered"))
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(AtlasColors.mint.opacity(0.72)))
                }
            }
        }
        .padding(11)
        .background(AtlasColors.mint.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .atlasMotion(expandedPicker)
    }

    private func filterSelector(
        kind: WordBankPickerKind,
        icon: String,
        title: String,
        value: String
    ) -> some View {
        let isExpanded = expandedPicker == kind

        return Button {
            AtlasHaptics.selection()
            withAnimation(.atlasSpring) {
                expandedPicker = isExpanded ? nil : kind
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .black))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                    Text(value)
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .black))
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: isExpanded ? AtlasColors.line.opacity(0.85) : .clear, radius: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func customPicker(for kind: WordBankPickerKind) -> some View {
        switch kind {
        case .level:
            VStack(spacing: 8) {
                pickerRow(
                    title: language.text(ru: "Все уровни", en: "All levels"),
                    subtitle: language.text(ru: "Показать A1-C2", en: "Show A1-C2"),
                    isSelected: levelFilter == nil
                ) {
                    levelFilter = nil
                    expandedPicker = nil
                }

                ForEach(LearningLevel.allCases) { level in
                    pickerRow(
                        title: "\(level.tag) · \(level.title(for: language))",
                        subtitle: level.shortCanDoRU,
                        isSelected: levelFilter == level
                    ) {
                        levelFilter = level
                        expandedPicker = nil
                    }
                }
            }
            .padding(10)
            .customDropdownSurface()

        case .topic:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                pickerChip(
                    title: language.text(ru: "Все темы", en: "All topics"),
                    icon: "square.grid.2x2",
                    isSelected: topicFilter == nil
                ) {
                    topicFilter = nil
                    expandedPicker = nil
                }

                ForEach(WordBank.topics, id: \.self) { topic in
                    pickerChip(
                        title: WordBank.topicTitle(topic, for: language),
                        icon: topicIcon(topic),
                        isSelected: topicFilter == topic
                    ) {
                        topicFilter = topic
                        expandedPicker = nil
                    }
                }
            }
            .padding(10)
            .customDropdownSurface()
        }
    }

    private func pickerRow(
        title: String,
        subtitle: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AtlasHaptics.selection()
            withAnimation(.atlasSpring) {
                action()
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(.black)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                    Text(subtitle)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(.black.opacity(0.56))
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 10)
            .background(isSelected ? AtlasColors.mint.opacity(0.62) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.black.opacity(isSelected ? 0.86 : 0.2), lineWidth: isSelected ? 1.8 : 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private func pickerChip(
        title: String,
        icon: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button {
            AtlasHaptics.selection()
            withAnimation(.atlasSpring) {
                action()
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .black))

                Text(title)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)

                Spacer(minLength: 0)
            }
            .foregroundStyle(.black)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(isSelected ? AtlasColors.mint.opacity(0.72) : .white)
            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(.black.opacity(isSelected ? 0.86 : 0.2), lineWidth: isSelected ? 1.8 : 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private func topicIcon(_ topic: String) -> String {
        switch topic {
        case "Everyday": "house"
        case "Work": "briefcase"
        case "Study": "book.closed"
        case "Emotions": "heart"
        case "Travel": "map"
        case "Business": "chart.line.uptrend.xyaxis"
        case "Health": "cross.case"
        case "Tech": "cpu"
        case "Culture": "theatermasks"
        case "Nature": "leaf"
        default: "square.grid.2x2"
        }
    }
}

private extension View {
    func customDropdownSurface() -> some View {
        background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 4)
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
