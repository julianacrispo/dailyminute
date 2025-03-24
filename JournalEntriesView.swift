import SwiftUI

struct JournalEntriesView: View {
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        List {
            ForEach(viewModel.journalEntries) { entry in
                VStack(alignment: .leading) {
                    Text(entry.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(entry.text)
                        .lineLimit(2)
                }
                .padding(.vertical, 5)
            }
        }
        .navigationTitle("Journal Entries")
    }
} 
