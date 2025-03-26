import SwiftUI

struct AppColors {
    // Main colors
    static let accent = Color(hex: "8B5CF6") // Rich purple accent color
    
    // Background colors
    static let background = Color.black // Pure black background
    static let cardBackground = Color(hex: "1A1A1A") // Dark gray for cards
    static let cardBackgroundSecondary = Color(hex: "202020") // Slightly lighter dark gray
    static let surfaceHighlight = Color(hex: "2A2A2A") // Highlight for interactive elements
    
    // Text colors
    static let textPrimary = Color.white // White for primary text
    static let textSecondary = Color(hex: "AAAAAA") // Light gray for secondary text
    static let textTertiary = Color(hex: "777777") // Medium gray for less important text
    
    // Status colors
    static let recording = Color(hex: "FF3366") // Red for recording indicators
    static let measurementNegative = Color(hex: "4388FF") // Blue for negative measurement (-2, -3 values)
    static let measurementPositive = Color(hex: "4CAF50") // Green for positive measurements
}

// Extension to create Color from hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
} 