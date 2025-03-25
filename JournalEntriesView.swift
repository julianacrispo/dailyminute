import SwiftUI

struct JournalEntriesView: View {
    @Bindable var viewModel: JournalViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Title area - centered
            Text("Your minutes")
                .font(.system(size: 20))
                .foregroundColor(Color(.systemGray))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 24)
            
            if viewModel.journalEntries.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "note.text")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)
                        .padding()
                    
                    Text("No minutes yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Your recorded minutes will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(viewModel.journalEntries.sorted(by: { $0.date > $1.date })) { entry in
                            NavigationLink(destination: JournalEntryDetailView(entry: entry, viewModel: viewModel)) {
                                HStack(alignment: .center, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formattedDate(entry.date))
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                        
                                        Text(entry.text)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(3)
                                            .multilineTextAlignment(.leading)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(.systemGray3))
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .padding(.vertical, 16)
                                .padding(.horizontal)
                            }
                            
                            if entry.id != viewModel.journalEntries.sorted(by: { $0.date > $1.date }).last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
                .background(Color.white)
            }
        }
        .background(Color.white)
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
