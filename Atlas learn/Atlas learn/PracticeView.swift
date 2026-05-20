//
//  PracticeView.swift
//  Atlas learn
//

import SwiftUI

struct PracticeView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile
    let words: [WordEntry]

    @State private var index = 0
    @State private var selectedChoice: String?
    @State private var lastAnswerWasCorrect: Bool?
    @State private var hearts = 3
    @State private var sessionXP = 0
    @State private var isFinished = false
    @State private var didCommitSession = false

    private var practiceWords: [WordEntry] {
        words.isEmpty ? Array(WordBank.all.prefix(profile.dailyGoal)) : words
    }

    private var currentWord: WordEntry {
        practiceWords[min(index, practiceWords.count - 1)]
    }

    var body: some View {
        ZStack {
            AtlasColors.paper
                .ignoresSafeArea()

            if isFinished {
                completionView
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                challengeView
                    .transition(.opacity.combined(with: .move(edge: .leading)))
            }
        }
        .atlasMotion(index)
        .atlasMotion(selectedChoice)
        .atlasMotion(lastAnswerWasCorrect)
        .atlasMotion(hearts)
        .atlasSoftMotion(isFinished)
        .atlasSoftMotion(profile.appLanguage)
    }

    private var challengeView: some View {
        VStack(spacing: 0) {
            practiceHeader

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    Text(profile.appLanguage.text(ru: "Выбери правильный перевод", en: "Choose the correct translation"))
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundStyle(.black)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(spacing: 12) {
                        Text(currentWord.english)
                            .font(.system(size: 52, weight: .black, design: .serif))
                            .foregroundStyle(.black)
                            .minimumScaleFactor(0.65)
                            .lineLimit(1)

                        Text(currentWord.ipa)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(.black.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34)
                    .background(AtlasColors.mint.opacity(0.72))
                    .clipShape(RoundedRectangle(cornerRadius: 34, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 34, style: .continuous)
                            .stroke(AtlasColors.line, lineWidth: 2.5)
                    )
                    .shadow(color: AtlasColors.line, radius: 0, y: 8)

                    VStack(spacing: 14) {
                        ForEach(WordBank.translationChoices(for: currentWord), id: \.self) { choice in
                            answerButton(choice)
                        }
                    }

                    Button {
                        selectAnswer(nil)
                    } label: {
                        Text(profile.appLanguage.text(ru: "Не помню", en: "I do not remember"))
                            .font(.system(size: 17, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.64))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                    .disabled(selectedChoice != nil)
                }
                .padding(.horizontal, 24)
                .padding(.top, 28)
                .padding(.bottom, 160)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let lastAnswerWasCorrect {
                feedbackBar(isCorrect: lastAnswerWasCorrect)
            }
        }
    }

    private var practiceHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 14) {
                    Button {
                        AtlasHaptics.tap()
                        dismiss()
                    } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(.black)
                        .frame(width: 42, height: 42)
                }
                .buttonStyle(.plain)

                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.black.opacity(0.08))

                        Capsule()
                            .fill(AtlasColors.green)
                            .frame(
                                width: proxy.size.width * CGFloat(Double(index) / Double(max(practiceWords.count, 1)))
                            )
                    }
                }
                .frame(height: 12)

                HStack(spacing: 3) {
                    ForEach(0..<3, id: \.self) { heart in
                        Image(systemName: heart < hearts ? "heart.fill" : "heart")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(heart < hearts ? AtlasColors.coral : .black.opacity(0.25))
                    }
                }
                .frame(width: 78)
            }

            HStack {
                CapsuleMetric(icon: "bolt.fill", title: "\(sessionXP) XP")
                Spacer()
                CapsuleMetric(icon: "bookmark", title: "\(index + 1)/\(practiceWords.count)")
            }
            .colorScheme(.dark)
        }
        .padding(.horizontal, 18)
        .padding(.top, 14)
        .padding(.bottom, 8)
    }

    private var completionView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                TinyDotsShadow()
                    .frame(width: 180, height: 86)
                    .offset(y: 54)

                Circle()
                    .fill(AtlasColors.mint)
                    .frame(width: 152, height: 152)
                    .overlay(Circle().stroke(.black, lineWidth: 3))
                    .shadow(color: AtlasColors.line, radius: 0, y: 8)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 76, weight: .black))
                    .foregroundStyle(.black)
            }

            Text(profile.appLanguage.text(ru: "Тренировка завершена", en: "Practice complete"))
                .font(.system(size: 36, weight: .black, design: .serif))
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)

            Text(profile.appLanguage.text(
                ru: "Ты закрепил слова дня. Ошибки автоматически остались в повторении.",
                en: "You reinforced today's words. Mistakes stayed in review automatically."
            ))
            .font(.system(size: 18, weight: .medium, design: .rounded))
            .foregroundStyle(.black.opacity(0.62))
            .multilineTextAlignment(.center)
            .lineSpacing(4)

            HStack(spacing: 14) {
                finishMetric(title: "XP", value: "+\(sessionXP)", icon: "bolt.fill")
                finishMetric(
                    title: profile.appLanguage.text(ru: "Серия", en: "Streak"),
                    value: "\(profile.streak)",
                    icon: "flame.fill"
                )
            }
            .padding(.top, 10)

            Button {
                AtlasHaptics.tap()
                dismiss()
            } label: {
                Text(profile.appLanguage.text(ru: "Вернуться к словам", en: "Back to words"))
                    .font(.system(size: 19, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .shadow(color: .black.opacity(0.36), radius: 0, y: 6)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)

            Spacer()
        }
        .padding(24)
    }

    private func answerButton(_ choice: String) -> some View {
        let isSelected = selectedChoice == choice
        let isCorrectChoice = choice == currentWord.russian
        let fill: Color = {
            guard selectedChoice != nil else { return .white }
            if isSelected && isCorrectChoice { return AtlasColors.green.opacity(0.28) }
            if isSelected && !isCorrectChoice { return AtlasColors.coral.opacity(0.35) }
            if isCorrectChoice { return AtlasColors.green.opacity(0.18) }
            return .white
        }()

        return Button {
            selectAnswer(choice)
        } label: {
            HStack(spacing: 12) {
                Text(choice)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(.black)

                Spacer()

                if selectedChoice != nil {
                    Image(systemName: isCorrectChoice ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 23, weight: .black))
                        .foregroundStyle(isCorrectChoice ? AtlasColors.green : .black.opacity(0.18))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(fill)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(AtlasColors.line, lineWidth: 2)
            )
            .shadow(color: AtlasColors.line, radius: 0, y: 6)
        }
        .buttonStyle(.plain)
        .disabled(selectedChoice != nil)
    }

    private func feedbackBar(isCorrect: Bool) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 26, weight: .bold))

                VStack(alignment: .leading, spacing: 3) {
                    Text(isCorrect ? profile.appLanguage.text(ru: "Верно", en: "Correct") : profile.appLanguage.text(ru: "Запомним это слово", en: "We will remember this word"))
                        .font(.system(size: 19, weight: .black, design: .rounded))

                    Text("\(currentWord.english) - \(currentWord.russian)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .opacity(0.78)
                }

                Spacer()
            }

            Button {
                AtlasHaptics.tap()
                continuePractice()
            } label: {
                Text(profile.appLanguage.text(ru: "Продолжить", en: "Continue"))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isCorrect ? AtlasColors.green : AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(.black)
        .padding(20)
        .background(AtlasColors.paper)
        .overlay(Rectangle().fill(.black.opacity(0.08)).frame(height: 1), alignment: .top)
    }

    private func finishMetric(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 26, weight: .black))
                .foregroundStyle(AtlasColors.green)

            Text(value)
                .font(.system(size: 30, weight: .black, design: .rounded))

            Text(title)
                .font(.system(size: 15, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.58))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 6)
    }

    private func selectAnswer(_ choice: String?) {
        guard selectedChoice == nil else { return }

        let isCorrect = choice == currentWord.russian

        if isCorrect {
            AtlasHaptics.success()
        } else {
            AtlasHaptics.error()
        }

        withAnimation(.atlasSpring) {
            selectedChoice = choice ?? ""
            lastAnswerWasCorrect = isCorrect
        }

        if isCorrect {
            sessionXP += 10
            profile.markCompleted(currentWord.id)
        } else {
            hearts = max(0, hearts - 1)
            profile.addUnknown(currentWord.id)
        }
    }

    private func continuePractice() {
        withAnimation(.atlasSpring) {
            selectedChoice = nil
            lastAnswerWasCorrect = nil
        }

        if hearts == 0 || index >= practiceWords.count - 1 {
            finishSession()
        } else {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                index += 1
            }
        }
    }

    private func finishSession() {
        guard !didCommitSession else {
            withAnimation(.atlasSoftSpring) {
                isFinished = true
            }
            return
        }

        didCommitSession = true
        profile.xp += sessionXP

        if sessionXP > 0 {
            profile.streak += 1
        }

        AtlasHaptics.success()

        withAnimation(.atlasSoftSpring) {
            isFinished = true
        }
    }
}
