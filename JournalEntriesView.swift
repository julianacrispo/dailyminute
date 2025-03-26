import SwiftUI

struct JournalEntriesView: View {
    @Bindable var viewModel: JournalViewModel
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Title area - left aligned like Eight Sleep
                Text("Minutes")
                    .titleStyle()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                if viewModel.journalEntries.isEmpty {
                    Spacer()
                    VStack(spacing: 24) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.textSecondary)
                            .padding()
                        
                        Text("No minutes yet")
                            .headerStyle()
                        
                        Text("Your recorded minutes will appear here")
                            .captionStyle()
                    }
                    .padding(40)
                    Spacer()
                } else {
                    // Tonight's routine card - Eight Sleep style
                    DarkCard {
                        HStack {
                            Text("Tonight's minutes")
                                .headerStyle()
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textSecondary)
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                    
                    // Journal entries with Eight Sleep card style
                    ScrollView {
                        VStack(spacing: 16) {
                            // Section header
                            HStack {
                                Text("Weekly minutes")
                                    .headerStyle()
                                
                                Spacer()
                                
                                Image(systemName: "plus")
                                    .foregroundColor(AppColors.textPrimary)
                                    .font(.system(size: 18, weight: .medium))
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                            
                            // Entry cards
                            ForEach(viewModel.journalEntries.sorted(by: { $0.date > $1.date })) { entry in
                                NavigationLink(destination: JournalEntryDetailView(entry: entry, viewModel: viewModel)) {
                                    DarkCard {
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Date and indicators
                                            HStack {
                                                Image(systemName: "waveform")
                                                    .foregroundColor(AppColors.textSecondary)
                                                
                                                Text(formatTime(entry.date))
                                                    .captionStyle()
                                                
                                                Spacer()
                                                
                                                Text(formatDate(entry.date))
                                                    .captionStyle()
                                            }
                                            
                                            DarkDivider()
                                            
                                            // Text preview
                                            Text(entry.text)
                                                .bodyStyle()
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                                .padding(.bottom, 4)
                                            
                                            // Bottom indicator
                                            HStack {
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right")
                                                    .foregroundColor(AppColors.textSecondary)
                                                    .font(.system(size: 14, weight: .medium))
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationView {
        JournalEntriesView(viewModel: {
            let viewModel = JournalViewModel()
            viewModel.journalEntries = [
                JournalEntry(text: "Today I had a fantastic meeting with the team. We discussed the new product roadmap."),
                JournalEntry(text: "Feeling motivated to start the new project tomorrow. Need to prepare the materials.")
            ]
            return viewModel
        }())
    }
    .preferredColorScheme(.dark)
} 
