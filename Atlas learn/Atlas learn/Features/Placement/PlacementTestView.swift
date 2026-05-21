//
//  PlacementTestView.swift
//  Atlas learn
//

import SwiftUI

struct PlacementTestView: View {
    let language: AppLanguage
    let selectedStartLevel: LearningLevel
    let selfEstimate: PlacementSelfEstimate
    let dailyGoal: Int
    let selectedTopics: [String]
    let onComplete: (PlacementResult) -> Void

    @State private var engine: PlacementEngine
    @State private var selectedAnswer: String?
    @State private var typedAnswer = ""
    @State private var itemStartedAt = Date()

    init(
        language: AppLanguage,
        selectedStartLevel: LearningLevel,
        selfEstimate: PlacementSelfEstimate,
        dailyGoal: Int,
        selectedTopics: [String],
        onComplete: @escaping (PlacementResult) -> Void
    ) {
        self.language = language
        self.selectedStartLevel = selectedStartLevel
        self.selfEstimate = selfEstimate
        self.dailyGoal = dailyGoal
        self.selectedTopics = selectedTopics
        self.onComplete = onComplete
        _engine = State(initialValue: PlacementEngine(selectedStartLevel: selectedStartLevel, selfEstimate: selfEstimate))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if let item = engine.currentItem {
                itemCard(item)
                    .id(item.id)
            } else {
                finishButton
            }
        }
        .onAppear {
            itemStartedAt = Date()
        }
        .atlasMotion(engine.answeredCount)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                CapsuleMetric(icon: "checklist", title: "\(engine.answeredCount)/45")
                CapsuleMetric(icon: "target", title: "\(Int((engine.confidence * 100).rounded()))%")
                Spacer()
                Text(selectedStartLevel.tag)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundStyle(.black.opacity(0.58))
            }

            Text(language.text(ru: "Адаптивный тест", en: "Adaptive placement"))
                .font(.system(size: 30, weight: .black, design: .serif))

            Text(language.text(
                ru: "Отвечай без подсказок. После ответа отметь, насколько уверенно было.",
                en: "Answer without hints. After each answer, mark how confident it felt."
            ))
            .font(.system(size: 14, weight: .bold, design: .rounded))
            .foregroundStyle(.black.opacity(0.62))
            .fixedSize(horizontal: false, vertical: true)
        }
        .foregroundStyle(.black)
    }

    private func itemCard(_ item: PlacementItem) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 8) {
                Label(item.skill.title(for: language), systemImage: item.skill.icon)
                    .font(.system(size: 13, weight: .black, design: .rounded))
                Spacer()
                Text(item.cefrLevel.tag)
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AtlasColors.mint.opacity(0.5)))
            }

            Text(prompt(for: item))
                .font(.system(size: 21, weight: .black, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)

            if let text = item.text {
                Text(text)
                    .font(textFont(for: item))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AtlasColors.mint.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.black.opacity(0.22), lineWidth: 1.4)
                    )
            }

            if let audioText = item.audioText {
                Button {
                    AtlasHaptics.tap()
                    AtlasSpeech.speak(audioText)
                } label: {
                    Label("Play", systemImage: "waveform.circle.fill")
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundStyle(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(AtlasColors.coral.opacity(0.24))
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(AtlasColors.line, lineWidth: 2)
                        )
                }
                .buttonStyle(.plain)
            }

            if item.options.isEmpty {
                typedAnswerField(item)
            } else {
                optionList(item)
            }

            if selectedAnswer != nil {
                confidenceRow(item)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            if engine.answeredCount >= 20 {
                Button {
                    finish(early: true)
                } label: {
                    Text(language.text(ru: "Завершить раньше", en: "Finish early"))
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(.black.opacity(0.58))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(AtlasColors.line, lineWidth: 2.1)
        )
        .shadow(color: AtlasColors.line, radius: 0, y: 5)
    }

    private func prompt(for item: PlacementItem) -> String {
        switch item.type {
        case .wordMeaning:
            language.text(ru: "Выбери перевод", en: "Choose the translation")
        default:
            item.prompt
        }
    }

    private func textFont(for item: PlacementItem) -> Font {
        item.type == .wordMeaning
            ? .system(size: 32, weight: .black, design: .serif)
            : .system(size: 16, weight: .bold, design: .rounded)
    }

    private func optionList(_ item: PlacementItem) -> some View {
        VStack(spacing: 10) {
            ForEach(item.options, id: \.self) { option in
                Button {
                    AtlasHaptics.selection()
                    withAnimation(.atlasSpring) {
                        selectedAnswer = option
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text(option)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: selectedAnswer == option ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 19, weight: .black))
                            .foregroundStyle(selectedAnswer == option ? .black : .black.opacity(0.25))
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                    .background(selectedAnswer == option ? AtlasColors.mint.opacity(0.48) : AtlasColors.paper.opacity(0.46))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.black.opacity(selectedAnswer == option ? 0.62 : 0.18), lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }

            if item.type == .wordMeaning {
                unknownWordButton
            }
        }
    }

    private var unknownWordButton: some View {
        let value = PlacementAnswerValue.unknownWord

        return Button {
            AtlasHaptics.selection()
            withAnimation(.atlasSpring) {
                selectedAnswer = value
            }
        } label: {
            HStack(spacing: 10) {
                Text(language.text(ru: "Я не знаю этого слова", en: "I don't know this word"))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: selectedAnswer == value ? "checkmark.circle.fill" : "questionmark.circle")
                    .font(.system(size: 19, weight: .black))
                    .foregroundStyle(selectedAnswer == value ? .black : .black.opacity(0.34))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(selectedAnswer == value ? AtlasColors.coral.opacity(0.34) : AtlasColors.paper.opacity(0.46))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(.black.opacity(selectedAnswer == value ? 0.62 : 0.18), lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func typedAnswerField(_ item: PlacementItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(language.text(ru: "Ответ", en: "Answer"), text: $typedAnswer, axis: .vertical)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .lineLimit(2...4)
                .padding(14)
                .background(AtlasColors.paper.opacity(0.55))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(.black.opacity(0.24), lineWidth: 1.5)
                )

            Button {
                guard !typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                withAnimation(.atlasSpring) {
                    selectedAnswer = typedAnswer
                }
            } label: {
                Text(language.text(ru: "Проверить", en: "Check"))
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 13)
                    .background(AtlasColors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .opacity(typedAnswer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.45 : 1)
        }
    }

    private func confidenceRow(_ item: PlacementItem) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(language.text(ru: "Как ощущалось?", en: "How did it feel?"))
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundStyle(.black.opacity(0.56))

            HStack(spacing: 8) {
                ForEach(AnswerConfidence.allCases) { confidence in
                    Button {
                        submit(item, confidence: confidence)
                    } label: {
                        Text(confidence.title(for: language))
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AtlasColors.mint.opacity(confidence == .ok ? 0.55 : 0.28))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .stroke(.black.opacity(0.28), lineWidth: 1.3)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var finishButton: some View {
        Button {
            finish(early: false)
        } label: {
            Text(language.text(ru: "Показать результат", en: "Show result"))
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(AtlasColors.ink)
                .clipShape(RoundedRectangle(cornerRadius: 21, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func submit(_ item: PlacementItem, confidence: AnswerConfidence) {
        guard let selectedAnswer else { return }
        let spent = Date().timeIntervalSince(itemStartedAt)
        engine.record(answer: selectedAnswer, for: item, timeSpent: spent, confidence: confidence)
        self.selectedAnswer = nil
        typedAnswer = ""
        itemStartedAt = Date()

        if engine.shouldStop {
            finish(early: false)
        }
    }

    private func finish(early: Bool) {
        let result = engine.finish(early: early, dailyGoal: dailyGoal, selectedTopics: selectedTopics)
        AtlasHaptics.success()
        onComplete(result)
    }
}
