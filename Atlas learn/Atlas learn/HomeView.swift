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

                Spacer(minLength: 80)

                wordCard

                Spacer(minLength: 56)

                actionRow

                Spacer(minLength: 34)

                bottomNavigation
            }
            .padding(.horizontal, 26)
            .padding(.top, 18)
            .padding(.bottom, 22)
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
            CircleIconButton(systemName: "person", size: 62) {
                showsProfile = true
            }

            Spacer()

            HStack(spacing: 12) {
                Image(systemName: "bookmark")
                    .font(.system(size: 19, weight: .semibold))

                Text("\(profile.completedTodayIDs.count)/\(profile.dailyGoal)")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.62))

                        Capsule()
                            .fill(.white)
                            .frame(width: proxy.size.width * min(progressValue, 1))
                    }
                }
                .frame(width: 112, height: 8)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .frame(height: 50)
            .background(Capsule().fill(Color.black.opacity(0.16)))
            .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1))
            .shadow(color: .black.opacity(0.22), radius: 14, y: 10)

            Spacer()

            CircleIconButton(systemName: "crown", size: 62) {
                showsProfile = true
            }
        }
    }

    private var wordCard: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text(currentWord.english.lowercased())
                    .font(.system(size: currentWord.english.count > 12 ? 54 : 64, weight: .black, design: .serif))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.68)
                    .lineLimit(1)

                Button {
                    nextWord()
                } label: {
                    HStack(spacing: 10) {
                        Text(currentWord.ipa)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Image(systemName: "speaker.wave.2")
                            .font(.system(size: 20, weight: .medium))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 9)
                    .background(Capsule().fill(Color.black.opacity(0.16)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            VStack(spacing: 12) {
                Text("(\(currentWord.partOfSpeech).) \(currentWord.definition(for: profile.appLanguage))")
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)

                Text(currentWord.russian)
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white.opacity(0.72))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, 4)
        }
        .frame(maxWidth: .infinity)
    }

    private var actionRow: some View {
        HStack(spacing: 42) {
            CircleIconButton(systemName: "info", size: 54) {
                showsInfo = true
            }

            CircleIconButton(systemName: "square.and.arrow.up", size: 54) {
                profile.markCompleted(currentWord.id)
                nextWord()
            }

            CircleIconButton(
                systemName: profile.favoriteWordIDs.contains(currentWord.id) ? "heart.fill" : "heart",
                foreground: profile.favoriteWordIDs.contains(currentWord.id) ? AtlasColors.coral : .white,
                size: 54
            ) {
                profile.toggleFavorite(currentWord.id)
            }

            CircleIconButton(
                systemName: profile.savedWordIDs.contains(currentWord.id) ? "bookmark.fill" : "bookmark",
                size: 54
            ) {
                profile.toggleSaved(currentWord.id)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var bottomNavigation: some View {
        HStack {
            CircleIconButton(systemName: "square.grid.2x2", size: 62) {
                showsWordBank = true
            }

            Spacer()

            Button {
                showsPractice = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "graduationcap")
                        .font(.system(size: 25, weight: .semibold))
                    Text(profile.appLanguage.text(ru: "Тренировка", en: "Practice"))
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 24)
                .frame(height: 62)
                .background(Capsule().fill(Color.black.opacity(0.16)))
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 1.2))
                .shadow(color: .black.opacity(0.24), radius: 14, y: 10)
            }
            .buttonStyle(.plain)

            Spacer()

            CircleIconButton(systemName: "chart.bar", size: 62) {
                showsStats = true
            }
        }
    }

    private func nextWord() {
        guard !dailyWords.isEmpty else { return }
        withAnimation(.spring(response: 0.36, dampingFraction: 0.82)) {
            currentIndex = (currentIndex + 1) % dailyWords.count
        }
    }

    private func previousWord() {
        guard !dailyWords.isEmpty else { return }
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
                    .font(.system(size: 46, weight: .black, design: .serif))

                Text(word.russian)
                    .font(.system(size: 28, weight: .black, design: .rounded))

                Text(word.definition(for: language))
                    .font(.system(size: 20, weight: .medium, design: .rounded))
                    .lineSpacing(4)

                Divider()

                Text(word.example(for: language))
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .lineSpacing(4)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AtlasColors.line, lineWidth: 2)
                    )

                Spacer()
            }
            .foregroundStyle(.black)
            .padding(24)
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
                    .font(.system(size: 40, weight: .black, design: .serif))

                HStack(spacing: 14) {
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
            .padding(24)
        }
    }

    private func statCard(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(AtlasColors.green)

            Text(value)
                .font(.system(size: 40, weight: .black, design: .rounded))

            Text(title)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundStyle(.black.opacity(0.62))
        }
        .foregroundStyle(.black)
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 6)
    }
}
