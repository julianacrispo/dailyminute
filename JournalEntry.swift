import Foundation

struct JournalEntry: Identifiable, Codable {
    var id = UUID()
    var text: String
    var date: Date
    
    init(text: String, date: Date = Date()) {
        self.text = text
        self.date = date
    }
} 
