import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @Bindable var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var editedText: String
    @State private var isEditing: Bool = false
    @State private var showSaveConfirmation: Bool = false
    @FocusState private var isFocused: Bool
    @State private var isTranscribing: Bool = false
    
    init(entry: JournalEntry, viewModel: JournalViewModel) {
        self.entry = entry
        self.viewModel = viewModel
        _editedText = State(initialValue: entry.text)
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header bar in Eight Sleep style
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                            .padding(10)
                    }
                    
                    Spacer()
                    
                    Text("Minute")
                        .headerStyle()
                    
                    Spacer()
                    
                    if isEditing {
                        Button("Done") {
                            stopTranscribing()
                            saveChanges()
                        }
                        .foregroundColor(AppColors.accent)
                        .padding(10)
                    } else {
                        Spacer()
                            .frame(width: 50)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Date header in Eight Sleep style
                        DarkCard {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(formattedDayOfWeek)
                                        .headerStyle()
                                    
                                    Text(formattedDateAndTime)
                                        .captionStyle()
                                }
                                
                                Spacer()
                                
                                // Day/night indicator (placeholder)
                                Image(systemName: "moon.stars.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        
                        // Journal content in dark theme
                        DarkCard {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Entry")
                                        .headerStyle()
                                    
                                    if !isEditing {
                                        Image(systemName: "pencil")
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.textSecondary)
                                            .padding(.leading, 4)
                                    }
                                    
                                    Spacer()
                                    
                                    // Time indicator
                                    Text(formattedTime)
                                        .captionStyle()
                                }
                                
                                DarkDivider()
                                
                                if isEditing {
                                    TextEditor(text: $editedText)
                                        .bodyStyle()
                                        .lineSpacing(6)
                                        .frame(minHeight: 200)
                                        .scrollContentBackground(.hidden)
                                        .background(Color.clear)
                                        .focused($isFocused)
                                        .onChange(of: isEditing) { newValue in
                                            if newValue {
                                                isFocused = true
                                                startTranscribing()
                                            } else {
                                                stopTranscribing()
                                            }
                                        }
                                } else {
                                    Text(entry.text)
                                        .bodyStyle()
                                        .lineSpacing(6)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            isEditing = true
                                        }
                                }
                                
                                // Audio recording indicator in Eight Sleep style
                                if isEditing && isTranscribing {
                                    HStack {
                                        AudioWaveform(level: viewModel.audioLevel)
                                            .frame(width: 120, height: 24)
                                        
                                        Text("Listening...")
                                            .captionStyle()
                                        
                                        Spacer()
                                    }
                                    .padding(.top, 8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Additional metrics in Eight Sleep style
                        DarkCard {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Metrics")
                                    .headerStyle()
                                
                                DarkDivider()
                                
                                HStack(spacing: 30) {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Word count")
                                            .captionStyle()
                                        Text("\(wordCount)")
                                            .headerStyle()
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Duration")
                                            .captionStyle()
                                        Text("1 min")
                                            .headerStyle()
                                    }
                                    
                                    Spacer()
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .overlay(
            Group {
                if showSaveConfirmation {
                    // Success animation when saved
                    VStack {
                        Spacer()
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppColors.accent)
                            Text("Changes saved")
                                .foregroundColor(AppColors.textPrimary)
                                .font(.headline)
                        }
                        .padding()
                        .background(AppColors.cardBackground.opacity(0.95))
                        .cornerRadius(10)
                        .shadow(color: Color.black.opacity(0.3), radius: 10)
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
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ResetMinutesNavigation"))) { _ in
            dismiss()
        }
        .onAppear {
            // Tell the parent that navigation is active
            NotificationCenter.default.post(name: NSNotification.Name("JournalNavigationActive"), object: nil)
        }
    }
    
    private var wordCount: Int {
        let words = entry.text.split(separator: " ")
        return words.count
    }
    
    private func startTranscribing() {
        viewModel.startTranscription(mode: .editing(editedText)) { newText in
            editedText = newText
        }
        isTranscribing = true
    }
    
    private func stopTranscribing() {
        if isTranscribing {
            viewModel.stopTranscription()
            isTranscribing = false
        }
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
    
    private var formattedDayOfWeek: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: entry.date)
    }
    
    private var formattedDateAndTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: entry.date)
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
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
    .preferredColorScheme(.dark)
} 