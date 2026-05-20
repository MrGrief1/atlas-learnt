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
    case sort
}

private enum WordBankSearchIndex {
    static let searchableTextByID: [String: String] = Dictionary(uniqueKeysWithValues: WordBank.all.map { word in
        (word.id, "\(word.english) \(word.russian) \(word.partOfSpeech) \(word.topic)".lowercased())
    })

    static let numericSuffixByID: [String: Int] = Dictionary(uniqueKeysWithValues: WordBank.all.map { word in
        (word.id, Int(word.id.split(separator: "-").last ?? "") ?? 0)
    })
}

private struct WordBankQueryContext {
    let language: AppLanguage
    let query: String
    let filter: WordBankFilter
    let sortOption: WordSortOption
    let levelFilter: LearningLevel?
    let topicFilter: String?
    let savedIDs: Set<String>
    let unknownIDs: Set<String>
    let weakIDs: Set<String>
    let selectedTopics: Set<String>
    let memories: [String: WordMemory]
    let currentLevel: LearningLevel

    init(
        language: AppLanguage,
        searchText: String,
        filter: WordBankFilter,
        sortOption: WordSortOption,
        levelFilter: LearningLevel?,
        topicFilter: String?,
        savedIDs: Set<String>,
        unknownIDs: Set<String>,
        weakIDs: Set<String>,
        selectedTopics: Set<String>,
        memories: [String: WordMemory],
        currentLevel: LearningLevel
    ) {
        self.language = language
        self.query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        self.filter = filter
        self.sortOption = sortOption
        self.levelFilter = levelFilter
        self.topicFilter = topicFilter
        self.savedIDs = savedIDs
        self.unknownIDs = unknownIDs
        self.weakIDs = weakIDs
        self.selectedTopics = selectedTopics
        self.memories = memories
        self.currentLevel = currentLevel
    }

    func matches(_ word: WordEntry) -> Bool {
        switch filter {
        case .all:
            break
        case .saved:
            guard savedIDs.contains(word.id) else { return false }
        case .unknown:
            guard unknownIDs.contains(word.id) else { return false }
        case .weak:
            guard weakIDs.contains(word.id) else { return false }
        case .mastered:
            guard (memories[word.id]?.mastery ?? 0) >= 70 else { return false }
        }

        if let levelFilter, word.level != levelFilter { return false }
        if let topicFilter, word.topic != topicFilter { return false }
        guard !query.isEmpty else { return true }
        return WordBankSearchIndex.searchableTextByID[word.id]?.contains(query) == true
    }

    func sorted(_ words: [WordEntry]) -> [WordEntry] {
        words.sorted(by: precedes)
    }

    private func precedes(_ left: WordEntry, _ right: WordEntry) -> Bool {
        switch sortOption {
        case .smart:
            let leftScore = smartSortScore(for: left)
            let rightScore = smartSortScore(for: right)
            if leftScore != rightScore { return leftScore < rightScore }
            return isAlphabeticallyBefore(left, right)
        case .alphabetic:
            return isAlphabeticallyBefore(left, right)
        case .level:
            if left.level != right.level { return left.level < right.level }
            return isAlphabeticallyBefore(left, right)
        case .masteryLow:
            let leftMastery = memories[left.id]?.mastery ?? 0
            let rightMastery = memories[right.id]?.mastery ?? 0
            if leftMastery != rightMastery { return leftMastery < rightMastery }
            return isAlphabeticallyBefore(left, right)
        case .masteryHigh:
            let leftMastery = memories[left.id]?.mastery ?? 0
            let rightMastery = memories[right.id]?.mastery ?? 0
            if leftMastery != rightMastery { return leftMastery > rightMastery }
            return isAlphabeticallyBefore(left, right)
        case .topic:
            let leftTopic = WordBank.topicTitle(left.topic, for: language)
            let rightTopic = WordBank.topicTitle(right.topic, for: language)
            if leftTopic != rightTopic { return leftTopic < rightTopic }
            return isAlphabeticallyBefore(left, right)
        case .dueFirst:
            let leftDue = memories[left.id]?.isDue() == true
            let rightDue = memories[right.id]?.isDue() == true
            if leftDue != rightDue { return leftDue && !rightDue }
            let leftScore = smartSortScore(for: left)
            let rightScore = smartSortScore(for: right)
            if leftScore != rightScore { return leftScore < rightScore }
            return isAlphabeticallyBefore(left, right)
        case .newest:
            let leftID = WordBankSearchIndex.numericSuffixByID[left.id] ?? 0
            let rightID = WordBankSearchIndex.numericSuffixByID[right.id] ?? 0
            if leftID != rightID { return leftID > rightID }
            return isAlphabeticallyBefore(left, right)
        }
    }

    private func smartSortScore(for word: WordEntry) -> Int {
        let memory = memories[word.id]
        let mastery = memory?.mastery ?? 0
        var score = 0

        if memory?.isDue() == true { score -= 700 }
        if unknownIDs.contains(word.id) { score -= 500 }
        if weakIDs.contains(word.id) { score -= 350 }
        if savedIDs.contains(word.id) { score -= 80 }
        if selectedTopics.contains(word.topic) { score -= 45 }

        score += abs(word.level.order - currentLevel.order) * 90
        score += mastery
        score += (WordBankSearchIndex.numericSuffixByID[word.id] ?? 0) % 17
        return score
    }

    private func isAlphabeticallyBefore(_ left: WordEntry, _ right: WordEntry) -> Bool {
        left.english.localizedCaseInsensitiveCompare(right.english) == .orderedAscending
    }
}

struct WordBankView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile

    @State private var searchText = ""
    @State private var filter: WordBankFilter = .all
    @State private var sortOption: WordSortOption = .smart
    @State private var levelFilter: LearningLevel?
    @State private var topicFilter: String?
    @State private var expandedPicker: WordBankPickerKind?
    @State private var selectedPracticeWord: WordEntry?
    @State private var displayedWords: [WordEntry] = []
    @State private var searchRefreshTask: Task<Void, Never>?

    private var language: AppLanguage {
        profile.appLanguage
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
                        ForEach(displayedWords) { word in
                            WordBankRow(word: word, profile: $profile) {
                                selectedPracticeWord = word
                            }
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
        .atlasMotion(sortOption)
        .onAppear(perform: refreshDisplayedWords)
        .onDisappear {
            searchRefreshTask?.cancel()
        }
        .onChange(of: searchText) { _, _ in
            scheduleSearchRefresh()
        }
        .onChange(of: filter) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: sortOption) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: levelFilter) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: topicFilter) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: profile.savedWordIDs) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: profile.unknownWordIDs) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: profile.wordProgress) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: profile.currentLevel) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: profile.selectedTopics) { _, _ in
            refreshDisplayedWords()
        }
        .onChange(of: profile.appLanguage) { _, _ in
            refreshDisplayedWords()
        }
        .fullScreenCover(item: $selectedPracticeWord) { word in
            PracticeView(
                profile: $profile,
                words: [word],
                startWordID: word.id
            )
        }
    }

    private func scheduleSearchRefresh() {
        searchRefreshTask?.cancel()
        searchRefreshTask = Task {
            try? await Task.sleep(nanoseconds: 220_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                refreshDisplayedWords()
            }
        }
    }

    private func refreshDisplayedWords() {
        searchRefreshTask?.cancel()
        let context = WordBankQueryContext(
            language: language,
            searchText: searchText,
            filter: filter,
            sortOption: sortOption,
            levelFilter: levelFilter,
            topicFilter: topicFilter,
            savedIDs: Set(profile.savedWordIDs),
            unknownIDs: Set(profile.unknownWordIDs),
            weakIDs: Set(profile.weakWordIDs),
            selectedTopics: Set(profile.selectedTopics),
            memories: profile.wordProgress,
            currentLevel: profile.currentLevel
        )

        displayedWords = context.sorted(WordBank.all.filter(context.matches))
    }

    private var filterControls: some View {
        VStack(spacing: 8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    countChip

                    filterSelector(
                        kind: .level,
                        icon: "slider.horizontal.3",
                        title: language.text(ru: "Уровень", en: "Level"),
                        value: levelFilter?.tag ?? language.text(ru: "Все", en: "All")
                    )
                    .frame(width: 142)

                    filterSelector(
                        kind: .topic,
                        icon: "square.grid.2x2",
                        title: language.text(ru: "Тема", en: "Topic"),
                        value: topicFilter.map { WordBank.topicTitle($0, for: language) } ?? language.text(ru: "Все", en: "All")
                    )
                    .frame(width: 166)

                    filterSelector(
                        kind: .sort,
                        icon: sortOption.icon,
                        title: language.text(ru: "Сортировка", en: "Sort"),
                        value: sortOption.title(for: language)
                    )
                    .frame(width: 174)

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
                            .frame(width: 46, height: 48)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(AtlasColors.line, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(levelFilter == nil && topicFilter == nil)
                    .opacity(levelFilter == nil && topicFilter == nil ? 0.45 : 1)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
            }
            .frame(height: 56)

            if let expandedPicker {
                customPicker(for: expandedPicker)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.vertical, 8)
        .background(AtlasColors.mint.opacity(0.34))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .atlasMotion(expandedPicker)
    }

    private var countChip: some View {
        HStack(spacing: 7) {
            Image(systemName: levelFilter != nil || topicFilter != nil ? "line.3.horizontal.decrease.circle.fill" : "number")
                .font(.system(size: 15, weight: .black))

            VStack(alignment: .leading, spacing: 2) {
                Text(language.text(ru: "Найдено", en: "Showing"))
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.black.opacity(0.56))
                Text(verbatim: "\(displayedWords.count)")
                    .font(.system(size: 15, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 10)
        .frame(width: 124, height: 48, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
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
            .frame(height: 48)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
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

        case .sort:
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(WordSortOption.allCases) { option in
                    pickerChip(
                        title: option.title(for: language),
                        icon: option.icon,
                        isSelected: sortOption == option
                    ) {
                        sortOption = option
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
    let practiceAction: () -> Void

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

                Text(word.exampleEN)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.black.opacity(0.6))
                    .lineLimit(2)

                Button {
                    AtlasHaptics.tap()
                    practiceAction()
                } label: {
                    Label(language.text(ru: "Проработать слово", en: "Practice this word"), systemImage: "play.circle.fill")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(AtlasColors.mint.opacity(0.5))
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(.black.opacity(0.28), lineWidth: 1.2))
                }
                .buttonStyle(.plain)
            }

            Spacer()

            VStack(spacing: 10) {
                Button {
                    AtlasHaptics.tap()
                    AtlasSpeech.speak(word.english, voice: profile.selectedSpeechVoice)
                } label: {
                    Image(systemName: "speaker.wave.2")
                        .font(.system(size: 18, weight: .bold))
                        .frame(width: 38, height: 38)
                }

                Button {
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        profile.toggleSaved(word.id)
                    }
                } label: {
                    Image(systemName: profile.savedWordIDs.contains(word.id) ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 19, weight: .bold))
                        .frame(width: 38, height: 38)
                }

                Button {
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        profile.toggleFavorite(word.id)
                    }
                } label: {
                    Image(systemName: profile.favoriteWordIDs.contains(word.id) ? "heart.fill" : "heart")
                        .font(.system(size: 19, weight: .bold))
                        .frame(width: 38, height: 38)
                }
            }
            .foregroundStyle(.black)
            .buttonStyle(.plain)
            .padding(.leading, 2)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
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
