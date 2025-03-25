import SwiftUI

struct JournalEntriesView: View {
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        VStack {
            // Title area - centered, matches main view
            Text("Daily Minute")
                .font(.system(size: 36, weight: .bold))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 20)
                .padding(.bottom, 10)
            
            if viewModel.journalEntries.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No journal entries yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your recorded entries will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
            } else {
                List {
                    ForEach(viewModel.journalEntries.sorted(by: { $0.date > $1.date })) { entry in
                        NavigationLink(destination: JournalEntryDetailView(entry: entry, viewModel: viewModel)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(formattedDate(entry.date))
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(entry.text)
                                    .font(.body)
                                    .lineLimit(2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
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
} 
