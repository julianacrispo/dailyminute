import SwiftUI

// Typography extension for consistent text styling
extension View {
    // Large title style - for main screen titles
    func titleStyle() -> some View {
        self.font(.system(size: 34, weight: .bold))
            .foregroundColor(AppColors.textPrimary)
    }
    
    // Subtitle style - for section headers
    func subtitleStyle() -> some View {
        self.font(.system(size: 22, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
    }
    
    // Header style - for card titles and important text
    func headerStyle() -> some View {
        self.font(.system(size: 17, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
    }
    
    // Body text style - for regular content
    func bodyStyle() -> some View {
        self.font(.system(size: 17, weight: .regular))
            .foregroundColor(AppColors.textPrimary)
            .lineSpacing(4)
    }
    
    // Caption style - for secondary information
    func captionStyle() -> some View {
        self.font(.system(size: 14, weight: .regular))
            .foregroundColor(AppColors.textSecondary)
    }
    
    // Micro caption - for timestamps and smallest text elements
    func microStyle() -> some View {
        self.font(.system(size: 12, weight: .regular))
            .foregroundColor(AppColors.textTertiary)
    }
    
    // Measurement style - for numbers like "-2" "-3" in Eight Sleep
    func measurementStyle() -> some View {
        self.font(.system(size: 20, weight: .medium))
            .foregroundColor(AppColors.measurementNegative)
    }
    
    // Label style - for buttons and interactive elements
    func labelStyle() -> some View {
        self.font(.system(size: 17, weight: .medium))
            .foregroundColor(AppColors.textPrimary)
    }
}

// Custom button styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.accent)
            .foregroundColor(.white)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17, weight: .medium))
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppColors.cardBackground)
            .foregroundColor(AppColors.textPrimary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppColors.textTertiary, lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
    }
}

struct IconButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? AppColors.accent.opacity(0.8) : AppColors.accent)
    }
}

// Card styles
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(16)
    }
}

extension View {
    func cardStyle() -> some View {
        self.modifier(CardStyle())
    }
} 