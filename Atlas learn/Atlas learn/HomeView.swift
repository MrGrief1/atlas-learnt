//
//  HomeView.swift
//  Atlas learn
//

import SwiftUI

struct HomeView: View {
    @Binding var profile: AtlasProfile

    let resetOnboarding: () -> Void

    @State private var currentIndex = 0
    @State private var showsProfile = false
    @State private var showsPractice = false
    @State private var showsWordBank = false
    @State private var showsStats = false
    @State private var showsInfo = false

    private var dailyWords: [WordEntry] {
        profile.dailyWords
    }

    private var currentWord: WordEntry {
        guard !dailyWords.isEmpty else { return WordBank.all[0] }
        return dailyWords[min(currentIndex, dailyWords.count - 1)]
    }

    private var progressValue: Double {
        Double(profile.completedTodayIDs.count) / Double(max(profile.dailyGoal, 1))
    }

    var body: some View {
        ZStack {
            AtlasColors.ink
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer(minLength: 72)

                wordCard
                    .id(currentWord.id)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))

                Spacer(minLength: 48)

                actionRow

                Spacer(minLength: 28)

                bottomNavigation
            }
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 18)
        }
        .gesture(
            DragGesture(minimumDistance: 26)
                .onEnded { value in
                    if value.translation.height < -24 || value.translation.width < -40 {
                        nextWord()
                    } else if value.translation.width > 40 {
                        previousWord()
                    }
                }
        )
        .atlasMotion(currentWord.id)
        .atlasSoftMotion(profile)
        .fullScreenCover(isPresented: $showsProfile) {
            ProfileView(
                profile: $profile,
                resetOnboarding: resetOnboarding
            )
        }
        .fullScreenCover(isPresented: $showsPractice) {
            PracticeView(
                profile: $profile,
                words: dailyWords
            )
        }
        .sheet(isPresented: $showsWordBank) {
            WordBankView(profile: $profile)
        }
        .sheet(isPresented: $showsStats) {
            StatsView(profile: profile)
        }
        .sheet(isPresented: $showsInfo) {
            WordInfoView(word: currentWord, language: profile.appLanguage)
                .presentationDetents([.medium])
        }
    }

    private var topBar: some View {
        HStack {
            CircleIconButton(systemName: "person", size: 56) {
                showsProfile = true
            }

            Spacer()

            HStack(spacing: 10) {
                Image(systemName: "bookmark")
                    .font(.system(size: 17, weight: .semibold))

                Text("\(profile.completedTodayIDs.count)/\(profile.dailyGoal)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.62))

                        Capsule()
                            .fill(.white)
                            .frame(width: proxy.size.width * min(progressValue, 1))
                    }
                }
                .frame(width: 96, height: 7)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 15)
            .frame(height: 44)
            .background(Capsule().fill(Color.black.opacity(0.16)))
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .shadow(color: .black.opacity(0.22), radius: 14, y: 10)

            Spacer()

            CircleIconButton(systemName: "crown", size: 56) {
                showsProfile = true
            }
        }
    }

    private var wordCard: some View {
        VStack(spacing: 21) {
            VStack(spacing: 10) {
                Text(currentWord.english.lowercased())
                    .font(.system(size: currentWord.english.count > 12 ? 46 : 56, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.68)
                    .lineLimit(1)

                Button {
                    nextWord()
                } label: {
                    HStack(spacing: 8) {
                        Text(currentWord.ipa)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 15)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.black.opacity(0.16)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 10) {
                Text("(\(currentWord.partOfSpeech).) \(currentWord.definition(for: profile.appLanguage))")
                    .font(.system(size: 23, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                Text(currentWord.russian)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 13)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionRow: some View {
        HStack(spacing: 34) {
            CircleIconButton(systemName: "info", size: 48) {
                showsInfo = true
            }

            CircleIconButton(systemName: "square.and.arrow.up", size: 48) {
                profile.markCompleted(currentWord.id)
                nextWord(triggerHaptic: false)
            }

            CircleIconButton(
                systemName: profile.favoriteWordIDs.contains(currentWord.id) ? "heart.fill" : "heart",
                foreground: profile.favoriteWordIDs.contains(currentWord.id) ? AtlasColors.coral : .white,
                size: 48
            ) {
                profile.toggleFavorite(currentWord.id)
            }

            CircleIconButton(
                systemName: profile.savedWordIDs.contains(currentWord.id) ? "bookmark.fill" : "bookmark",
                size: 48
            ) {
                profile.toggleSaved(currentWord.id)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomNavigation: some View {
        HStack {
            CircleIconButton(systemName: "square.grid.2x2", size: 56) {
                showsWordBank = true
            }

            Spacer()

            Button {
                AtlasHaptics.tap()
                showsPractice = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "graduationcap")
                        .font(.system(size: 21, weight: .semibold))
                    Text(profile.appLanguage.text(ru: "Тренировка", en: "Practice"))
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .frame(height: 54)
                .background(Capsule().fill(Color.black.opacity(0.16)))
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1.2))
                .shadow(color: .black.opacity(0.24), radius: 14, y: 10)
            }
            .buttonStyle(.plain)

            Spacer()

            CircleIconButton(systemName: "chart.bar", size: 56) {
                showsStats = true
            }
        }
    }

    private func nextWord(triggerHaptic: Bool = true) {
        guard !dailyWords.isEmpty else { return }

        if triggerHaptic {
            AtlasHaptics.impact(.soft)
        }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            currentIndex = (currentIndex + 1) % dailyWords.count
        }
    }

    private func previousWord(triggerHaptic: Bool = true) {
        guard !dailyWords.isEmpty else { return }

        if triggerHaptic {
            AtlasHaptics.impact(.soft)
        }

        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            currentIndex = (currentIndex - 1 + dailyWords.count) % dailyWords.count
        }
    }
}

struct WordInfoView: View {
    let word: WordEntry
    let language: AppLanguage

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

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

                Divider()

                Text(word.example(for: language))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .lineSpacing(4)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(AtlasColors.line, lineWidth: 2)
                    )

                Spacer()
            }
            .foregroundStyle(.black)
            .padding(20)
        }
    }
}

struct StatsView: View {
    let profile: AtlasProfile

    var body: some View {
        ZStack {
            AtlasColors.paper.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 22) {
                Text(profile.appLanguage.text(ru: "Статистика", en: "Stats"))
                    .font(.system(size: 34, weight: .black, design: .serif))

                HStack(spacing: 12) {
                    statCard(
                        icon: "flame.fill",
                        title: profile.appLanguage.text(ru: "Серия", en: "Streak"),
                        value: "\(profile.streak)"
                    )
                    statCard(
                        icon: "bolt.fill",
                        title: "XP",
                        value: "\(profile.xp)"
                    )
                }

                statCard(
                    icon: "checkmark.seal.fill",
                    title: profile.appLanguage.text(ru: "Сегодня выучено", en: "Completed today"),
                    value: "\(profile.completedTodayIDs.count)/\(profile.dailyGoal)"
                )

                Spacer()
            }
            .padding(20)
        }
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .black))
                .foregroundStyle(AtlasColors.green)

            Text(value)
                .font(.system(size: 33, weight: .black, design: .rounded))

            Text(title)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .foregroundStyle(.black)
        .padding(15)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }
}
