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
    @State private var journalNavigationActive = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Home/Recording tab - Keep the microphone icon
            ContentView(viewModel: viewModel)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
                .tag(0)
            
            // Journal entries tab - Change to calendar icon
            NavigationView {
                JournalEntriesView(viewModel: viewModel)
            }
            .tabItem {
                Label("Minutes", systemImage: "calendar")
            }
            .tag(1)
            .onChange(of: selectedTab) { newValue in
                // If we're switching to the Minutes tab and we're already on it
                // (meaning a secondary navigation is active), pop to root
                if newValue == 1 && journalNavigationActive {
                    journalNavigationActive = false
                    // Use a slight delay to avoid conflicts with the tab change animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NotificationCenter.default.post(name: NSNotification.Name("ResetMinutesNavigation"), object: nil)
                    }
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("JournalNavigationActive"))) { _ in
            // Set the flag when navigation occurs in the journal section
            journalNavigationActive = true
        }
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
