//
//  DailyMinuteApp.swift
//  DailyMinute
//
//  Created by Juliana Crispo on 3/24/25.
//

import SwiftUI

@main
struct DailyMinuteApp: App {
    @State private var viewModel = JournalViewModel()
    @State private var selectedTab = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                TabView(selection: $selectedTab) {
                    ContentView(viewModel: viewModel)
                        .tabItem {
                            Label("Record", systemImage: "mic")
                        }
                        .tag(0)
                    
                    NavigationView {
                        JournalEntriesView(viewModel: viewModel)
                    }
                    .tabItem {
                        Label("Minutes", systemImage: "list.bullet")
                    }
                    .tag(1)
                }
                .tint(Color.black)
                .onChange(of: selectedTab) { _ in
                    // This triggers a UI refresh when tab changes
                }
            }
        }
    }
}
