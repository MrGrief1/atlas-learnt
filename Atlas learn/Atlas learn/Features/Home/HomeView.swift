//
//  HomeView.swift
//  Atlas learn
//

import SwiftUI

struct HomeView: View {
    @Binding var profile: AtlasProfile

    let resetOnboarding: () -> Void

    @State private var currentIndex = 0
    @State private var selectedWordID: WordEntry.ID?
    @State private var showsProfile = false
    @State private var showsPractice = false
    @State private var showsPracticeHub = false
    @State private var showsLessonLauncher = false
    @State private var showsWordBank = false
    @State private var showsStats = false
    @State private var showsDailyProgress = false
    @State private var selectedLessonMode: LessonMode = .daily
    @State private var selectedLessonWord: WordEntry?
    @State private var selectedInfoWord: WordEntry?
    @State private var generatedExamples: [WordEntry.ID: GeneratedWordExample] = [:]
    @State private var generatingExampleIDs: Set<WordEntry.ID> = []
    @State private var cachedDailyWords: [WordEntry] = []

    private var dailyWords: [WordEntry] {
        cachedDailyWords.isEmpty ? profile.dailyWords : cachedDailyWords
    }

    private var currentWord: WordEntry {
        guard !dailyWords.isEmpty else { return WordBank.all[0] }

        if let selectedWordID,
           let selectedWord = dailyWords.first(where: { $0.id == selectedWordID }) {
            return selectedWord
        }

        return dailyWords[min(currentIndex, dailyWords.count - 1)]
    }

    private var dailyWordsRefreshToken: DailyWordsRefreshToken {
        DailyWordsRefreshToken(
            currentLevel: profile.currentLevel,
            score: profile.atlasScore,
            dailyGoal: profile.dailyGoal,
            selectedTopics: profile.selectedTopics,
            unknownWordIDs: profile.unknownWordIDs,
            savedWordIDs: profile.savedWordIDs,
            practiceCount: profile.practiceHistory.count,
            xp: profile.xp,
            lastStudyDateKey: profile.lastStudyDateKey
        )
    }

    private var progressValue: Double {
        Double(profile.completedTodayCount) / Double(max(profile.dailyGoal, 1))
    }

    var body: some View {
        ZStack {
            PremiumHomeBackground()
            wordPager
                .ignoresSafeArea(.container, edges: .vertical)
        }
        .safeAreaInset(edge: .top) {
            topBar
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .background(PremiumTopFade())
        }
        .safeAreaInset(edge: .bottom) {
            bottomNavigation
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
        }
        .onAppear {
            AtlasHaptics.prepare()
            profile.prepareForToday()
            refreshDailyWords()
        }
        .onChange(of: dailyWordsRefreshToken) { _, _ in
            refreshDailyWords()
        }
        .task(id: currentWord.id) {
            let word = currentWord
            try? await Task.sleep(nanoseconds: 320_000_000)
            guard !Task.isCancelled else { return }
            await generateExampleIfNeeded(for: word)
        }
        .sheet(isPresented: $showsProfile) {
            ProfileView(
                profile: $profile,
                resetOnboarding: resetOnboarding
            )
        }
        .fullScreenCover(isPresented: $showsPractice) {
            LessonPlayerView(
                profile: $profile,
                mode: selectedLessonMode,
                selectedWord: selectedLessonWord
            )
        }
        .sheet(isPresented: $showsLessonLauncher) {
            LessonLaunchView(
                profile: $profile,
                mode: selectedLessonMode,
                selectedWord: selectedLessonWord
            ) {
                showsLessonLauncher = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    showsPractice = true
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsPracticeHub) {
            PracticeHubView(profile: $profile) { mode in
                showsPracticeHub = false

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                    openLessonLauncher(mode: mode, word: nil)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showsWordBank) {
            WordBankView(profile: $profile)
        }
        .sheet(isPresented: $showsStats) {
            StatsView(profile: profile)
        }
        .sheet(isPresented: $showsDailyProgress) {
            DailyProgressView(profile: $profile) {
                showsDailyProgress = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
                    openLessonLauncher(mode: .daily, word: nil)
                }
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $selectedInfoWord) { word in
            WordInfoView(word: word, language: profile.appLanguage)
                .presentationDetents([.large])
        }
    }

    private var topBar: some View {
        HStack {
            homeIconButton(systemName: "person", size: 56) {
                showsProfile = true
            }

            Spacer()

            Button {
                AtlasHaptics.tap()
                showsDailyProgress = true
            } label: {
                HStack(spacing: 10) {
                    Text("EN")
                        .font(.system(size: 13, weight: .black, design: .rounded))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.16)))

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Text("\(profile.completedTodayCount)/\(profile.dailyGoal)")
                                .font(.system(size: 16, weight: .black, design: .rounded))
                            Text("\(profile.levelTag) \(profile.atlasScore)")
                                .font(.system(size: 11, weight: .heavy, design: .rounded))
                                .opacity(0.72)
                        }

                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.30))

                                Capsule()
                                    .fill(.white)
                                    .frame(width: proxy.size.width * min(progressValue, 1))
                            }
                        }
                        .frame(height: 6)
                    }
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 13)
                .frame(width: 174, height: 48)
                .background(Capsule().fill(AtlasColors.deepInk))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
                .shadow(color: .black.opacity(0.22), radius: 14, y: 10)
            }
            .buttonStyle(.plain)

            Spacer()

            homeIconButton(systemName: "crown", size: 56) {
                showsProfile = true
            }
        }
    }

    private var wordPager: some View {
        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(dailyWords) { word in
                        wordPage(for: word, in: proxy.size)
                            .frame(width: proxy.size.width, height: proxy.size.height)
                            .id(word.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .contentMargins(.vertical, 0, for: .scrollContent)
            .scrollPosition(id: $selectedWordID)
            .onChange(of: selectedWordID) { _, newID in
                syncSelectedWord(newID, feedback: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func wordPage(for word: WordEntry, in size: CGSize) -> some View {
        let topReserve: CGFloat = size.height < 760 ? 132 : 154
        let dockReserve: CGFloat = size.height < 760 ? 118 : 138

        return VStack(spacing: 0) {
            Spacer(minLength: topReserve)

            PremiumWordHeroView(
                word: word,
                example: displayedExample(for: word),
                status: exampleStatus(for: word),
                language: profile.appLanguage,
                isFavorite: profile.favoriteWordIDs.contains(word.id),
                isSaved: profile.savedWordIDs.contains(word.id),
                speak: {
                    speak(word)
                },
                showInfo: {
                    selectedInfoWord = word
                },
                drill: {
                    openLessonLauncher(mode: .wordDrill, word: word)
                },
                toggleFavorite: {
                    profile.toggleFavorite(word.id)
                },
                toggleSaved: {
                    profile.toggleSaved(word.id)
                }
            )
            .padding(.horizontal, AtlasLayout.screenPadding)

            Spacer(minLength: dockReserve)
        }
        .frame(width: size.width, height: size.height)
    }

    private var bottomNavigation: some View {
        HStack(spacing: 12) {
            CleanHomeBarButton(
                icon: "square.grid.2x2",
                title: profile.appLanguage.text(ru: "Слова", en: "Words")
            ) {
                AtlasHaptics.tap()
                showsWordBank = true
            }

            Button {
                AtlasHaptics.tap()
                showsPracticeHub = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 20, weight: .black))

                    Text(profile.appLanguage.text(ru: "Практика", en: "Practice"))
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(AtlasColors.mint)
                .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 23, style: .continuous)
                        .stroke(Color.black.opacity(0.86), lineWidth: 1.8)
                )
                .shadow(color: .black.opacity(0.42), radius: 0, y: 5)
            }
            .buttonStyle(.plain)

            CleanHomeBarButton(
                icon: "chart.bar",
                title: profile.appLanguage.text(ru: "Статы", en: "Stats")
            ) {
                AtlasHaptics.tap()
                showsStats = true
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(Color(red: 0.075, green: 0.075, blue: 0.08).opacity(0.94))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.34), radius: 18, y: 10)
    }

    private func displayedExample(for word: WordEntry) -> GeneratedWordExample {
        generatedExamples[word.id] ?? AtlasExampleGenerator.fallbackExample(for: word)
    }

    private func exampleStatus(for word: WordEntry) -> ExampleDisplayStatus {
        if generatedExamples[word.id] != nil {
            return .generated
        }

        if generatingExampleIDs.contains(word.id) {
            return .generating
        }

        return .local
    }

    private func generateExampleIfNeeded(for word: WordEntry) async {
        guard AtlasExampleGenerator.isAvailable else { return }
        guard generatedExamples[word.id] == nil, !generatingExampleIDs.contains(word.id) else { return }

        generatingExampleIDs.insert(word.id)
        defer { generatingExampleIDs.remove(word.id) }

        guard let generated = await AtlasExampleGenerator.generateExample(for: word) else { return }
        generatedExamples[word.id] = generated
    }

    private func homeIconButton(
        systemName: String,
        foreground: Color = .white,
        size: CGFloat = 52,
        action: @escaping () -> Void
    ) -> some View {
        CircleIconButton(
            systemName: systemName,
            foreground: foreground,
            fill: AtlasColors.deepInk,
            border: Color.white.opacity(0.16),
            size: size,
            action: action
        )
    }

    private func nextWord(triggerHaptic: Bool = true) {
        guard !dailyWords.isEmpty else { return }

        let targetIndex = min(currentIndex + 1, dailyWords.count - 1)
        guard targetIndex != currentIndex else {
            if triggerHaptic {
                AtlasHaptics.impact(.soft)
            }
            return
        }

        if triggerHaptic {
            AtlasHaptics.impact(.soft)
        }

        scrollToWord(at: targetIndex)
    }

    private func openLessonLauncher(mode: LessonMode, word: WordEntry?) {
        AtlasHaptics.tap()
        selectedLessonMode = mode
        selectedLessonWord = word
        showsLessonLauncher = true
    }

    private func speak(_ word: WordEntry) {
        AtlasHaptics.tap()
        AtlasSpeech.speak(word.english, voice: profile.selectedSpeechVoice)
    }

    private func previousWord(triggerHaptic: Bool = true) {
        guard !dailyWords.isEmpty else { return }

        let targetIndex = max(currentIndex - 1, 0)
        guard targetIndex != currentIndex else {
            if triggerHaptic {
                AtlasHaptics.impact(.soft)
            }
            return
        }

        if triggerHaptic {
            AtlasHaptics.impact(.soft)
        }

        scrollToWord(at: targetIndex)
    }

    private func scrollToWord(at index: Int) {
        let targetIndex = max(0, min(index, dailyWords.count - 1))
        let targetID = dailyWords[targetIndex].id

        withoutAnimation {
            currentIndex = targetIndex
        }

        withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
            selectedWordID = targetID
        }
    }

    private func refreshDailyWords() {
        let words = WordBank.dailyWords(for: profile)

        withoutAnimation {
            cachedDailyWords = words
            alignSelectedWord()
        }
    }

    private func alignSelectedWord() {
        guard !dailyWords.isEmpty else { return }

        if let selectedWordID,
           let selectedIndex = dailyWords.firstIndex(where: { $0.id == selectedWordID }) {
            currentIndex = selectedIndex
        } else {
            let safeIndex = min(currentIndex, dailyWords.count - 1)
            currentIndex = safeIndex
            selectedWordID = dailyWords[safeIndex].id
        }
    }

    private func syncSelectedWord(_ wordID: WordEntry.ID?, feedback: Bool) {
        guard
            let wordID,
            let selectedIndex = dailyWords.firstIndex(where: { $0.id == wordID }),
            currentIndex != selectedIndex
        else {
            return
        }

        withoutAnimation {
            currentIndex = selectedIndex
        }

        if feedback {
            DispatchQueue.main.async {
                AtlasHaptics.selection()
            }
        }
    }

    private func withoutAnimation(_ updates: () -> Void) {
        var transaction = Transaction()
        transaction.animation = nil
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            updates()
        }
    }
}

private struct CleanHomeBarButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            VStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 19, weight: .black))

                Text(title)
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(.white.opacity(0.82))
            .frame(width: 68, height: 58)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(Color.white.opacity(0.09), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct DailyWordsRefreshToken: Equatable {
    let currentLevel: LearningLevel
    let score: Int
    let dailyGoal: Int
    let selectedTopics: [String]
    let unknownWordIDs: [String]
    let savedWordIDs: [String]
    let practiceCount: Int
    let xp: Int
    let lastStudyDateKey: String
}

struct WordInfoView: View {
    let word: WordEntry
    let language: AppLanguage

    @State private var generatedExample: GeneratedWordExample?
    @State private var isGeneratingExample = false

    private var example: GeneratedWordExample {
        generatedExample ?? AtlasExampleGenerator.fallbackExample(for: word)
    }

    private var exampleStatus: ExampleDisplayStatus {
        if generatedExample != nil { return .generated }
        if isGeneratingExample { return .generating }
        return .local
    }

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    CapsuleMetric(icon: "graduationcap", title: "\(word.level.tag) \(word.level.title(for: language))")
                        .foregroundStyle(.black)

                    Text(word.english)
                        .font(.system(size: 38, weight: .black, design: .serif))

                    Text(word.russian)
                        .font(.system(size: 23, weight: .black, design: .rounded))

                    Text(word.definition(for: language))
                        .font(.system(size: 17, weight: .medium, design: .rounded))
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()

                    VStack(alignment: .leading, spacing: 8) {
                        Text(example.english)
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)

                        Text(example.russian)
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.68))
                            .fixedSize(horizontal: false, vertical: true)

                        ExampleStatusPill(status: exampleStatus, language: language)
                    }
                    .lineSpacing(4)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(AtlasColors.line, lineWidth: 2)
                    )

                    Spacer(minLength: 12)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.vertical, 20)
            }
        }
        .task(id: word.id) {
            await generateExampleIfNeeded()
        }
    }

    private func generateExampleIfNeeded() async {
        guard AtlasExampleGenerator.isAvailable, generatedExample == nil, !isGeneratingExample else { return }
        isGeneratingExample = true
        defer { isGeneratingExample = false }
        generatedExample = await AtlasExampleGenerator.generateExample(for: word)
    }
}
