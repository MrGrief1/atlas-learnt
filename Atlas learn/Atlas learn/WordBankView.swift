//
//  WordBankView.swift
//  Atlas learn
//

import SwiftUI

enum WordBankFilter: String, CaseIterable, Identifiable {
    case all
    case saved
    case unknown

    var id: String { rawValue }

    func title(for language: AppLanguage) -> String {
        switch self {
        case .all: language.text(ru: "Все", en: "All")
        case .saved: language.text(ru: "Сохраненные", en: "Saved")
        case .unknown: language.text(ru: "Повторить", en: "Review")
        }
    }
}

struct WordBankView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var profile: AtlasProfile

    @State private var searchText = ""
    @State private var filter: WordBankFilter = .all

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
            }

            guard matchesFilter else { return false }

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

                Picker("", selection: $filter) {
                    ForEach(WordBankFilter.allCases) { filter in
                        Text(filter.title(for: language))
                            .tag(filter)
                    }
                }
                .pickerStyle(.segmented)

                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredWords) { word in
                            WordBankRow(word: word, profile: $profile)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 20)
        }
        .atlasMotion(filter)
        .atlasSoftMotion(searchText)
        .atlasSoftMotion(profile)
        .onChange(of: filter) { _, _ in
            AtlasHaptics.selection()
        }
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
