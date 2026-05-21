//
//  ContentView.swift
//  Atlas learn
//
//  Created by Maks on 5/20/26.
//

import SwiftUI

struct ContentView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("atlas.hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("atlas.profile") private var storedProfile = ""

    @State private var profile = AtlasProfile.default
    @State private var isPreparingHome = false
    @State private var profileSaveTask: Task<Void, Never>?

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                if isPreparingHome {
                    AtlasLaunchView(language: profile.appLanguage)
                } else {
                    HomeView(
                        profile: $profile,
                        resetOnboarding: resetOnboarding
                    )
                }
            } else {
                OnboardingView { completedProfile in
                    profile = completedProfile
                    saveNow(completedProfile)
                    hasCompletedOnboarding = true
                }
            }
        }
        .task(id: hasCompletedOnboarding) {
            await prepareVisibleProfile()
        }
        .dynamicTypeSize(.medium)
        .preferredColorScheme(.light)
        .tint(.black)
        .atlasSoftMotion(hasCompletedOnboarding)
        .atlasSoftMotion(dynamicTypeSize)
        .onChange(of: profile) { _, newValue in
            scheduleSave(newValue)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                saveNow(profile)
            }
        }
    }

    private func loadProfile() -> AtlasProfile {
        guard
            let data = storedProfile.data(using: .utf8),
            let decoded = try? JSONDecoder().decode(AtlasProfile.self, from: data)
        else {
            return .default
        }

        return decoded
    }

    @MainActor
    private func prepareVisibleProfile() async {
        guard hasCompletedOnboarding else {
            isPreparingHome = false
            profile = loadProfile()
            return
        }

        isPreparingHome = true
        let loadedProfile = storedProfile.isEmpty ? profile : loadProfile()
        let preparedProfile = await Task.detached(priority: .userInitiated) {
            let words = WordBank.all
            _ = WordBank.allByID
            _ = WordBank.searchableTextByID
            _ = WordBank.numericSuffixByID
            _ = WordBank.levelCounts

            var profile = loadedProfile
            profile.prepareForToday(words: words)
            return profile
        }.value

        guard !Task.isCancelled else { return }
        profile = preparedProfile
        isPreparingHome = false
    }

    private func scheduleSave(_ profile: AtlasProfile) {
        profileSaveTask?.cancel()
        profileSaveTask = Task {
            try? await Task.sleep(nanoseconds: 350_000_000)
            guard !Task.isCancelled else { return }
            await save(profile)
        }
    }

    private func saveNow(_ profile: AtlasProfile) {
        profileSaveTask?.cancel()
        profileSaveTask = Task {
            await save(profile)
        }
    }

    @MainActor
    private func save(_ profile: AtlasProfile) async {
        let json = await Task.detached(priority: .utility) {
            Self.encodedProfileJSON(profile)
        }.value

        guard !Task.isCancelled, let json else { return }
        storedProfile = json
    }

    nonisolated private static func encodedProfileJSON(_ profile: AtlasProfile) -> String? {
        guard
            let data = try? JSONEncoder().encode(profile),
            let json = String(data: data, encoding: .utf8)
        else {
            return nil
        }

        return json
    }

    private func resetOnboarding() {
        profileSaveTask?.cancel()
        profile = .default
        storedProfile = ""
        isPreparingHome = false
        hasCompletedOnboarding = false
    }
}

private struct AtlasLaunchView: View {
    let language: AppLanguage

    var body: some View {
        ZStack {
            PremiumHomeBackground()

            VStack(spacing: 14) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)

                Text(language.text(ru: "Готовим слова", en: "Preparing words"))
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(.white.opacity(0.88))
            }
        }
    }
}

#Preview {
    ContentView()
}
