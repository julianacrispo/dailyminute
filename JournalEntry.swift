import Foundation

struct JournalEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var date: Date
    
    init(text: String, date: Date = Date()) {
        self.text = text
        self.date = date
    }
    
    // Implement Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        return lhs.id == rhs.id
    }
} 
