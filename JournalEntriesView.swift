import SwiftUI
import UIKit

// Define a struct to make each calendar day uniquely identifiable
struct DateIdentifiable: Identifiable, Hashable {
    let id = UUID()
    let date: Date?
    let gridPosition: Int  // Add grid position for extra uniqueness
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(gridPosition)
    }
    
    static func == (lhs: DateIdentifiable, rhs: DateIdentifiable) -> Bool {
        return lhs.id == rhs.id
    }
}

struct JournalEntriesView: View {
    @Bindable var viewModel: JournalViewModel
    @State private var selectedDate: Date = Date()
    @State private var currentMonth: Date = Date()
    
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
                VStack(spacing: 12) {
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
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppColors.textSecondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Calendar grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
                        ForEach(daysInMonth()) { dateItem in
                            if let date = dateItem.date {
                                Button {
                                    selectedDate = date
                                    
                                    // Get entries for the selected date
                                    let entriesForDay = entriesForDate(date)
                                    let entriesCount = entriesForDay.count
                                    
                                    // Provide haptic feedback when a day is tapped
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.prepare()
                                    generator.impactOccurred()
                                    
                                    // Navigate based on entries count
                                    if entriesCount > 0 {
                                        if entriesCount == 1 {
                                            // If there's exactly one entry, go directly to detail view
                                            viewModel.selectedEntry = entriesForDay[0]
                                        } else {
                                            // If there are multiple entries, go to day entries view
                                            viewModel.selectedDay = date
                                        }
                                    }
                                    // If no entries, just update the selected date (already done above)
                                } label: {
                                    CalendarDayButton(
                                        date: date,
                                        isSelected: isSameDay(date, selectedDate),
                                        hasEntries: hasEntriesForDate(date),
                                        isCurrentMonth: isSameMonth(date, currentMonth),
                                        action: { }
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            } else {
                                // Empty space for days not in current month
                                Color.clear
                                    .frame(height: 44)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 12)
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
                                Button {
                                    // Navigate to entry detail
                                    viewModel.selectedEntry = entry
                                } label: {
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
        }
    }
    
    // Calendar helper functions
    private func daysInMonth() -> [DateIdentifiable] {
        let calendar = Calendar.current
        
        // Get start of the month
        let startDate = calendar.date(from: calendar.dateComponents([.year, .month], from: currentMonth))!
        
        // Get the weekday of the first day (0 = Sunday, 1 = Monday, etc.)
        let firstWeekday = calendar.component(.weekday, from: startDate)
        
        // Calculate offset to fill the grid from Sunday
        let offset = firstWeekday - 1
        
        // Create array with offset placeholders and days of the month
        var days: [DateIdentifiable] = []
        
        // Add empty placeholders for days before the first of the month
        for position in 0..<offset {
            days.append(DateIdentifiable(date: nil, gridPosition: position))
        }
        
        // Get the range of days in month
        let daysInMonth = calendar.range(of: .day, in: .month, for: startDate)!.count
        
        // Add actual days of the month
        for day in 1...daysInMonth {
            if let date = calendar.date(byAdding: .day, value: day - 1, to: startDate) {
                days.append(DateIdentifiable(date: date, gridPosition: offset + day - 1))
            }
        }
        
        // Ensure we have complete weeks (multiples of 7) by adding placeholders at the end
        let remainingDays = (7 - (days.count % 7)) % 7
        for position in 0..<remainingDays {
            days.append(DateIdentifiable(date: nil, gridPosition: offset + daysInMonth + position))
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
        
        // Extract just the year, month, and day components to ignore time
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        
        // Compare only the date parts
        return components1.year == components2.year && 
               components1.month == components2.month && 
               components1.day == components2.day
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
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        
        let entries = viewModel.journalEntries.filter { entry in
            let result = isSameDay(entry.date, date)
            return result
        }
        
        return entries
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
    
    var body: some View {
        ZStack {
            dayContent
        }
        .contentShape(Rectangle()) // Ensure the entire area is tappable
        .accessibilityLabel("\(Calendar.current.component(.day, from: date))")
        .accessibilityHint(hasEntries ? "Has entries" : "No entries")
    }
    
    private var dayContent: some View {
        VStack(spacing: 2) {
            // Circle above the number
            ZStack {
                // Base circle (empty or filled)
                Circle()
                    .fill(hasEntries ? AppColors.accent : Color.clear)
                    .frame(width: 28, height: 28)
                
                // White outline for selected day
                if isSelected {
                    Circle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                } else {
                    // Non-selected days show empty circle outline
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 0.5)
                        .frame(width: 28, height: 28)
                }
            }
            
            // Day number with underline for current day
            VStack(spacing: 0) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(textColor)
                
                // Underline for current day
                if isSameDay(date, Date()) && isCurrentMonth {
                    Rectangle()
                        .fill(AppColors.accent)
                        .frame(width: 14, height: 1.5)
                        .padding(.top, 1)
                } else {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 14, height: 1.5)
                        .padding(.top, 1)
                }
            }
        }
        .frame(height: 44)
        .frame(maxWidth: .infinity)
    }
    
    private var textColor: Color {
        if !isCurrentMonth {
            return AppColors.textTertiary
        } else if isSelected {
            return Color.white
        } else {
            return AppColors.textSecondary
        }
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        
        // Extract just the year, month, and day components to ignore time
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        
        // Compare only the date parts
        return components1.year == components2.year && 
               components1.month == components2.month && 
               components1.day == components2.day
    }
}

// Day Entries View - Shows all entries for a specific day
struct DayEntriesView: View {
    let date: Date
    @Bindable var viewModel: JournalViewModel
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                // Header without back button
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                // Number of minutes
                Text("\(entriesForDate().count) minutes")
                    .captionStyle()
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                
                if entriesForDate().isEmpty {
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
                        VStack(spacing: 16) {
                            ForEach(entriesForDate().sorted(by: { $0.date > $1.date })) { entry in
                                Button {
                                    // Navigate to entry detail
                                    viewModel.selectedEntry = entry
                                } label: {
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
        }
    }
    
    // Helper functions
    private func entriesForDate() -> [JournalEntry] {
        return viewModel.journalEntries.filter { entry in
            isSameDay(entry.date, date)
        }
    }
    
    private func wordCount(_ text: String) -> Int {
        return text.split(separator: " ").count
    }
    
    private func isSameDay(_ date1: Date, _ date2: Date) -> Bool {
        let calendar = Calendar.current
        
        // Extract just the year, month, and day components to ignore time
        let components1 = calendar.dateComponents([.year, .month, .day], from: date1)
        let components2 = calendar.dateComponents([.year, .month, .day], from: date2)
        
        // Compare only the date parts
        return components1.year == components2.year && 
               components1.month == components2.month && 
               components1.day == components2.day
    }
    
    // Formatters
    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy" // Shortened month format
        return formatter
    }()
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
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
