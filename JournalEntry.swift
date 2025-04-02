import Foundation

struct JournalEntry: Identifiable, Codable, Hashable {
    var id = UUID()
    var text: String
    var date: Date
    var audioURL: URL?
    
    init(text: String, date: Date = Date(), audioURL: URL? = nil) {
        self.text = text
        self.date = date
        self.audioURL = audioURL
    }
    
    // Implement Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: JournalEntry, rhs: JournalEntry) -> Bool {
        return lhs.id == rhs.id
    }
} 
