import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedText: String
    @State private var isEditing: Bool = false
    @State private var showSaveConfirmation: Bool = false
    
    init(entry: JournalEntry, viewModel: JournalViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        _editedText = State(initialValue: entry.text)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Date header
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedDate)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(formattedTime)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                Divider()
                
                // Journal content - either text or textarea depending on edit mode
                if isEditing {
                    TextEditor(text: $editedText)
                        .font(.body)
                        .padding(10)
                        .frame(minHeight: 200)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                } else {
                    Text(entry.text)
                        .font(.body)
                        .lineSpacing(6)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Journal Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if isEditing {
                    Button("Save") {
                        saveChanges()
                    }
                } else {
                    Button("Edit") {
                        isEditing = true
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if isEditing {
                    Button("Cancel") {
                        // Discard changes and exit edit mode
                        editedText = entry.text
                        isEditing = false
                    }
                }
            }
        }
        .overlay(
            Group {
                if showSaveConfirmation {
                    // Success animation when saved
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Changes saved")
                                .foregroundColor(.green)
                                .font(.headline)
                        }
                        .padding()
                        .background(Color(.systemBackground).opacity(0.95))
                        .cornerRadius(10)
                        .shadow(radius: 3)
                        .padding(.bottom, 30)
                        
                        Spacer(minLength: 50)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showSaveConfirmation)
                    .onAppear {
                        // Haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // Auto dismiss the confirmation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showSaveConfirmation = false
                            }
                        }
                    }
                }
            }
        )
    }
    
    private func saveChanges() {
        // Update the entry immediately in the ViewModel
        viewModel.updateEntry(id: entry.id, newText: editedText)
        
        // Exit edit mode
        isEditing = false
        
        // Show confirmation
        withAnimation {
            showSaveConfirmation = true
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: entry.date)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }
}

#Preview {
    NavigationView {
        JournalEntryDetailView(
            entry: JournalEntry(text: "This is a sample journal entry with some text to display in the detail view. It's a test of how the layout will look with a longer text passage."),
            viewModel: JournalViewModel()
        )
    }
} 