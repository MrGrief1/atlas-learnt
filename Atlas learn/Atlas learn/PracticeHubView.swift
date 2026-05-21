//
//  PracticeHubView.swift
//  Atlas learn
//

import SwiftUI

struct PracticeHubView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let start: (LessonMode) -> Void

    private var language: AppLanguage {
        profile.appLanguage
    }

    var body: some View {
        ZStack {
            PracticeHubBackground()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header

                    LessonPathView(profile: profile) { mode in
                        start(mode)
                    }

                    quickActions

                    adaptiveHint
                }
                .padding(.horizontal, AtlasLayout.screenPadding)
                .padding(.top, 22)
                .padding(.bottom, 30)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(language.text(ru: "Практика", en: "Practice"))
                    .font(.system(size: 36, weight: .black, design: .serif))
                    .foregroundStyle(.white)

                Text(language.text(
                    ru: "Путь, повторение, ошибки и тренировки в одном месте.",
                    en: "Path, review, mistakes, and focused drills in one place."
                ))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()

            Button {
                AtlasHaptics.tap()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white.opacity(0.09)))
                    .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 1.2))
            }
            .buttonStyle(.plain)
        }
    }

    private var quickActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(language.text(ru: "Быстрые тренировки", en: "Quick practice"))
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                PracticeHubCard(
                    icon: "arrow.clockwise",
                    title: language.text(ru: "Повторение", en: "Review"),
                    subtitle: language.text(ru: "\(profile.dueWordsCount) слов ждут", en: "\(profile.dueWordsCount) due"),
                    accent: AtlasColors.mint
                ) {
                    start(.review)
                }

                PracticeHubCard(
                    icon: "cross.case.fill",
                    title: language.text(ru: "Ошибки", en: "Mistakes"),
                    subtitle: language.text(ru: "\(profile.weakWordIDs.count) слабых", en: "\(profile.weakWordIDs.count) weak"),
                    accent: AtlasColors.coral
                ) {
                    start(.weakWords)
                }

                PracticeHubCard(
                    icon: "headphones",
                    title: language.text(ru: "Listening", en: "Listening"),
                    subtitle: language.text(ru: "Слух и диктант", en: "Audio + dictation"),
                    accent: Color(red: 0.70, green: 0.84, blue: 1.0)
                ) {
                    start(.listening)
                }

                PracticeHubCard(
                    icon: "crown.fill",
                    title: "Boss Check",
                    subtitle: language.text(ru: "Проверка без подсказок", en: "No-hint check"),
                    accent: Color(red: 1.0, green: 0.84, blue: 0.42)
                ) {
                    start(.boss)
                }
            }
        }
    }

    private var adaptiveHint: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 9) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 18, weight: .black))

                Text(language.text(ru: "Atlas подстраивается", en: "Atlas adapts"))
                    .font(.system(size: 17, weight: .black, design: .rounded))
            }

            Text(language.text(
                ru: "Система запоминает ошибки, скорость ответа, типы заданий и mastery каждого слова. Если слово путается - оно вернётся в другом формате.",
                en: "The system remembers mistakes, response speed, task types, and mastery for every word. If a word is shaky, it returns in another format."
            ))
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.58))
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.white)
        .padding(16)
        .background(Color.white.opacity(0.065))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.09), lineWidth: 1)
        )
    }
}

private struct PracticeHubBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.04, blue: 0.045),
                    Color(red: 0.09, green: 0.09, blue: 0.095),
                    Color(red: 0.035, green: 0.035, blue: 0.04)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.white.opacity(0.08),
                    Color.clear,
                    AtlasColors.mint.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}

private struct PracticeHubCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button {
            AtlasHaptics.tap()
            action()
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .black))
                    .foregroundStyle(.black)
                    .frame(width: 46, height: 46)
                    .background(Circle().fill(accent))
                    .overlay(Circle().stroke(Color.black.opacity(0.82), lineWidth: 1.6))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)

                    Text(subtitle)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.52))
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(15)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
