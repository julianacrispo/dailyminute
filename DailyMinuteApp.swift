//
//  DailyMinuteApp.swift
//  DailyMinute
//
//  Created by Juliana Crispo on 3/24/25.
//

import SwiftUI

@main
struct DailyMinuteApp: App {
    @StateObject private var viewModel = JournalViewModel()
    
    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView(viewModel: viewModel)
                    .tabItem {
                        Label("Record", systemImage: "mic")
                    }
                
                NavigationView {
                    JournalEntriesView(viewModel: viewModel)
                }
                .tabItem {
                    Label("Entries", systemImage: "list.bullet")
                }
            }
        }
    }
}
