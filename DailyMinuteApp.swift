//
//  DailyMinuteApp.swift
//  DailyMinute
//
//  Created by Juliana Crispo on 3/24/25.
//

import SwiftUI

@main
struct DailyMinuteApp: App {
    @State private var hasCompletedOnboarding = false
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
            } else {
                MainTabView(viewModel: viewModel)
                    .preferredColorScheme(.dark) // Force dark mode for entire app
            }
        }
    }
}

// Main tab view for navigation between app sections
struct MainTabView: View {
    @ObservedObject var viewModel: JournalViewModel
    @State private var selectedTab = 0
    @State private var journalNavigationPath = NavigationPath()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Recording tab - Keep the microphone icon
            ContentView(viewModel: viewModel)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(0)
            
            // Journal entries tab - Using NavigationStack with path
            NavigationStack(path: $journalNavigationPath) {
                JournalEntriesView(viewModel: viewModel)
                    .navigationDestination(for: Date.self) { date in
                        DayEntriesView(date: date, viewModel: viewModel)
                    }
                    .navigationDestination(for: JournalEntry.self) { entry in
                        JournalEntryDetailView(entry: entry, viewModel: viewModel)
                    }
            }
            .tabItem {
                Label("Minutes", systemImage: "calendar")
            }
            .tag(1)
            .onChange(of: selectedTab) { newValue in
                // If we're switching to the Minutes tab and we're not at the root
                if newValue == 1 && !journalNavigationPath.isEmpty {
                    // Clear the navigation path to return to the root
                    journalNavigationPath = NavigationPath()
                    viewModel.selectedDay = nil
                    viewModel.selectedEntry = nil
                }
            }
            // Observe selectedEntry changes to update navigation
            .onChange(of: viewModel.selectedEntry) { entry in
                if let entry = entry {
                    journalNavigationPath.append(entry)
                }
            }
            // Observe selectedDay changes to update navigation
            .onChange(of: viewModel.selectedDay) { day in
                if let day = day {
                    journalNavigationPath.append(day)
                }
            }
            
            // Vibes measurement tab (formerly Score)
            ScorePlaceholderView()
                .tabItem {
                    Label("Vibes", systemImage: "gauge")
                }
                .tag(2)
            
            // Insights tab (formerly Stats)
            StatsPlaceholderView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb.fill")
                }
                .tag(3)
        }
        .accentColor(AppColors.accent) // Set accent color for tab bar
        .onAppear {
            // Style tab bar to match Eight Sleep dark theme
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = UIColor.black
            
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
        .preferredColorScheme(.dark) // Using explicit enum case
    }
}

// Placeholder views for tabs not yet implemented
struct StatsPlaceholderView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Insights")
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                Spacer()
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Insights")
                    .headerStyle()
                
                Text("Insights and trends will be available here")
                    .captionStyle()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

struct ProfilePlaceholderView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Profile")
                    .titleStyle()
                    .padding(.top, 40)
                
                Spacer()
                
                Image(systemName: "person.circle")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Coming Soon")
                    .headerStyle()
                
                Text("Profile settings will be available here")
                    .captionStyle()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}

// Placeholder view for the Score tab
struct ScorePlaceholderView: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Vibes")
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                Spacer()
                
                Image(systemName: "gauge")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Vibes")
                    .headerStyle()
                
                Text("A measure of your vibes will appear here")
                    .captionStyle()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
        }
    }
}
