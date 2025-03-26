import SwiftUI

struct JournalEntriesView: View {
    @Bindable var viewModel: JournalViewModel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    @State private var selectedEntry: JournalEntry? = nil
    
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
                
                // Calendar view
                VStack(spacing: 16) {
                    // Month navigation
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(AppColors.textPrimary)
                                .font(.system(size: 16, weight: .semibold))
                                .padding(8)
                        }
                        
                        Spacer()
                        
                        Text(monthYearFormatter.string(from: currentMonth))
                            .headerStyle()
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .foregroundColor(AppColors.textPrimary)
                                .font(.system(size: 16, weight: .semibold))
                                .padding(8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Day of week headers
                    HStack(spacing: 0) {
                        ForEach(Calendar.current.shortWeekdaySymbols, id: \.self) { day in
                            Text(day)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(daysInMonth(), id: \.self) { date in
                            if let date = date {
                                CalendarDayButton(
                                    date: date,
                                    isSelected: isSameDay(date, selectedDate),
                                    hasEntries: hasEntriesForDate(date),
                                    isCurrentMonth: isSameMonth(date, currentMonth),
                                    action: {
                                        selectedDate = date
                                    },
                                    viewModel: viewModel,
                                    onEntrySelected: { entry in
                                        selectedEntry = entry
                                    }
                                )
                            } else {
                                // Empty space for days not in current month
                                Color.clear
                                    .frame(height: 44)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
                .background(AppColors.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal)
                .padding(.top, 10)
                
                // Selected day entries
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(dayFormatter.string(from: selectedDate))
                            .headerStyle()
                        
                        Spacer()
                        
                        Text("\(entriesForSelectedDate().count) minutes")
                            .captionStyle()
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    
                    if entriesForSelectedDate().isEmpty {
                        Spacer()
                        VStack(spacing: 20) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.textSecondary)
                            
                            Text("No minutes recorded")
                                .headerStyle()
                            
                            Text("Record minutes to see them appear here for this day")
                                .captionStyle()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        Spacer()
                    } else {
                        ScrollView {
                            ForEach(entriesForSelectedDate().sorted(by: { $0.date > $1.date })) { entry in
                                NavigationLink(destination: JournalEntryDetailView(entry: entry, viewModel: viewModel)) {
                                    DarkCard {
                                        VStack(alignment: .leading, spacing: 12) {
                                            // Time and indicators
                                            HStack {
                                                Image(systemName: "waveform")
                                                    .foregroundColor(AppColors.textSecondary)
                                                
                                                Text(timeFormatter.string(from: entry.date))
                                                    .captionStyle()
                                                
                                                Spacer()
                                                
                                                // Word count indicator
                                                HStack(spacing: 4) {
                                                    Text("\(wordCount(entry.text))")
                                                        .captionStyle()
                                                    
                                                    Image(systemName: "text.word.count")
                                                        .font(.system(size: 12))
                                                        .foregroundColor(AppColors.textSecondary)
                                                }
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
                            .padding(.bottom, 16)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .background(
                // Hidden navigation link that will be activated programmatically
                NavigationLink(
                    destination: Group {
                        if let entry = selectedEntry {
                            JournalEntryDetailView(entry: entry, viewModel: viewModel)
                        }
                    },
                    isActive: Binding(
                        get: { selectedEntry != nil },
                        set: { if !$0 { selectedEntry = nil } }
                    )
                ) {
                    EmptyView()
                }
            )
        }
    }
    
    // Calendar helper functions
    private func daysInMonth() -> [Date?] {
        let calendar = Calendar.current
        
        // Get start of the month
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: startDate)
        
        // Calculate offset to fill the grid from Sunday
        let offset = firstWeekday - 1
        
        // Get the range of days in month
        let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count
        
        // Create array with offset placeholders and days of the month
        var days = Array(repeating: nil as Date?, count: offset)
        
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) {
                days.append(date)
            }
        }
        
        // Ensure we have complete weeks (multiples of 7)
        while days.count % 7 != 0 {
            days.append(nil)
        }
        
        return days
    }
    
    private func previousMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: -1, to: currentMonth) {
            withAnimation {
                currentMonth = newDate
            }
        }
    }
    
    private func nextMonth() {
        if let newDate = Calendar.current.date(byAdding: .month, value: 1, to: currentMonth) {
            withAnimation {
                currentMonth = newDate
            }
        }
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
    
    private func isSameMonth(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        let components1 = calendar.dateComponents([.year, .month], from: date1)
        let components2 = calendar.dateComponents([.year, .month], from: date2)
        return components1.year == components2.year && components1.month == components2.month
    }
    
    private func hasEntriesForDate(_ date: Date) -> Bool {
        return !entriesForDate(date).isEmpty
    }
    
    private func entriesForDate(_ date: Date) -> [JournalEntry] {
        return viewModel.journalEntries.filter { entry in
            isSameDay(entry.date, date)
        }
    }
    
    private func entriesForSelectedDate() -> [JournalEntry] {
        return entriesForDate(selectedDate)
    }
    
    private func wordCount(_ text: String) -> Int {
        return text.split(separator: " ").count
    }
    
    // Formatters
    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()
    
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

// Calendar day button
struct CalendarDayButton: View {
    let date: Date
    let isSelected: Bool
    let hasEntries: Bool
    let isCurrentMonth: Bool
    let action: () -> Void
    let viewModel: JournalViewModel
    let onEntrySelected: (JournalEntry) -> Void
    
    var body: some View {
        Button(action: {
            // Select the day first (updates UI)
            action()
            
            // If there are entries, navigate to the first one
            if hasEntries {
                navigateToFirstEntry()
            }
        }) {
            VStack(spacing: 4) {
                // Day number inside a circle
                ZStack {
                    // Background circle - filled for days with entries
                    Circle()
                        .fill(backgroundFill)
                        .frame(width: 36, height: 36)
                    
                    // Day number text
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(textColor)
                }
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Function to navigate to the first entry for this day
    private func navigateToFirstEntry() {
        if hasEntries {
            let entriesForDay = viewModel.journalEntries.filter { entry in
                Calendar.current.isDate(entry.date, inSameDayAs: date)
            }.sorted(by: { $0.date < $1.date })
            
            if let firstEntry = entriesForDay.first {
                onEntrySelected(firstEntry)
            }
        }
    }
    
    // Determine the fill color for the day circle
    private var backgroundFill: Color {
        if !isCurrentMonth {
            return Color.clear
        } else if isSelected {
            return AppColors.accent
        } else if hasEntries {
            return AppColors.accent
        } else if isSameDay(date, Date()) {
            return AppColors.accent.opacity(0.2)
        } else {
            return Color.clear
        }
    }
    
    // Determine text color based on state
    private var textColor: Color {
        if !isCurrentMonth {
            return AppColors.textTertiary
        } else if isSelected || hasEntries {
            return Color.white // White text on purple background
        } else if isSameDay(date, Date()) {
            return AppColors.accent // Purple text for today
        } else {
            return AppColors.textPrimary
        }
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(date1, inSameDayAs: date2)
    }
}

#Preview {
    NavigationView {
        JournalEntriesView(viewModel: {
            let viewModel = JournalViewModel()
            // Create sample entries for today
            let today = Date()
            viewModel.journalEntries = [
                JournalEntry(text: "Morning reflection: Today I had a fantastic meeting with the team.", date: today),
                JournalEntry(text: "Evening thoughts: Feeling motivated to start the new project tomorrow.", 
                             date: Calendar.current.date(byAdding: .hour, value: -5, to: today)!)
            ]
            // Add an entry for yesterday
            if let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today) {
                viewModel.journalEntries.append(
                    JournalEntry(text: "Yesterday's note: Need to follow up on the client meeting from yesterday.", date: yesterday)
                )
            }
            // Add an entry for last week
            if let lastWeek = Calendar.current.date(byAdding: .day, value: -7, to: today) {
                viewModel.journalEntries.append(
                    JournalEntry(text: "Last week's reflection: The project is progressing well.", date: lastWeek)
                )
            }
            return viewModel
        }())
    }
    .preferredColorScheme(.dark)
} 
