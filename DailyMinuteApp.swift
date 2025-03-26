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
    
    var body: some View {
        TabView {
            // Home/Recording tab
            ContentView(viewModel: viewModel)
                .tabItem {
                    Label("Record", systemImage: "mic.fill")
                }
            
            // Journal entries tab
            NavigationView {
                JournalEntriesView(viewModel: viewModel)
            }
            .tabItem {
                Label("Minutes", systemImage: "note.text")
            }
            
            // Placeholder for stats tab
            StatsPlaceholderView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            // Placeholder for profile tab
            ProfilePlaceholderView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
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
                Text("Stats")
                    .titleStyle()
                    .padding(.top, 40)
                
                Spacer()
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 80))
                    .foregroundColor(AppColors.textSecondary)
                
                Text("Coming Soon")
                    .headerStyle()
                
                Text("Stats and insights will be available here")
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
