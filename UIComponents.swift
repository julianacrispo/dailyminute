import SwiftUI

// Animated water-like gradient effect
struct WaterGradientView: View {
    @State private var phase = 0.0
    @State private var ripplePhase1 = 0.0
    @State private var ripplePhase2 = 0.0
    @State private var ripplePhase3 = 0.0
    @State private var innerBreathingScale = 1.0
    let animationSpeed: Double
    let isRecording: Bool
    
    init(animationSpeed: Double = 1.0, isRecording: Bool = false) {
        self.animationSpeed = animationSpeed
        self.isRecording = isRecording
    }
    
    var body: some View {
        ZStack {
            // Fixed outer circle container to maintain constant perimeter
            Circle()
                .fill(Color(hex: "6B46C1")) // Base purple color for outer perimeter
                .frame(width: 160, height: 160)
            
            // Animated inner content
            GeometryReader { geometry in
                ZStack {
                    // Base gradient with purples and blues
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(hex: "7668EC"), // Purple
                            Color(hex: "6B46C1"), // Deeper purple
                            Color(hex: "4A1FB8"), // Dark purple-blue
                            Color(hex: "3451B2"), // Blue
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    
                    // First ripple layer - slow moving
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "4F46E5").opacity(0.0), // Invisible center
                                    Color(hex: "4F46E5").opacity(0.6), // Indigo blue
                                    Color(hex: "4F46E5").opacity(0.0)  // Invisible outer
                                ]),
                                center: .center,
                                startRadius: geometry.size.width * 0.05,
                                endRadius: geometry.size.width * (0.35 + 0.3 * sin(ripplePhase1 * .pi))
                            )
                        )
                        .scaleEffect(0.7 + 0.3 * sin(ripplePhase1 * .pi))
                        .blendMode(.plusLighter)
                    
                    // Second ripple layer - medium speed, different color
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "3B82F6").opacity(0.0), // Invisible center
                                    Color(hex: "3B82F6").opacity(0.65), // Blue
                                    Color(hex: "3B82F6").opacity(0.0)  // Invisible outer
                                ]),
                                center: .center,
                                startRadius: geometry.size.width * 0.08,
                                endRadius: geometry.size.width * (0.45 + 0.25 * sin(ripplePhase2 * .pi))
                            )
                        )
                        .scaleEffect(0.65 + 0.3 * sin(ripplePhase2 * .pi * 0.8))
                        .blendMode(.plusLighter)
                    
                    // Third ripple layer - faster, different phase
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "8B5CF6").opacity(0.0), // Invisible center
                                    Color(hex: "8B5CF6").opacity(0.7), // Purple
                                    Color(hex: "8B5CF6").opacity(0.0)  // Invisible outer
                                ]),
                                center: .center,
                                startRadius: geometry.size.width * 0.02,
                                endRadius: geometry.size.width * (0.3 + 0.25 * sin(ripplePhase3 * .pi))
                            )
                        )
                        .scaleEffect(0.8 + 0.2 * sin(ripplePhase3 * .pi * 1.5))
                        .blendMode(.plusLighter)
                }
                .scaleEffect(innerBreathingScale)
            }
            .frame(width: 154, height: 154) // Slightly smaller to ensure it stays within perimeter
            .clipShape(Circle())
        }
        .onAppear {
            // Start continuous ripple animations with different timing
            withAnimation(.easeInOut(duration: 5 * animationSpeed).repeatForever(autoreverses: true)) {
                ripplePhase1 = 1.0
            }
            
            withAnimation(.easeInOut(duration: 4 * animationSpeed).repeatForever(autoreverses: true)) {
                ripplePhase2 = 1.0
            }
            
            withAnimation(.easeInOut(duration: 3 * animationSpeed).repeatForever(autoreverses: true)) {
                ripplePhase3 = 1.0
            }
            
            // Create a breathing animation effect for inner content only
            withAnimation(.easeInOut(duration: 2.5 * animationSpeed).repeatForever(autoreverses: true)) {
                innerBreathingScale = isRecording ? 0.97 : 0.95
            }
            
            withAnimation(.linear(duration: 20 * animationSpeed).repeatForever(autoreverses: false)) {
                phase = 1.0
            }
        }
        .onChange(of: isRecording) { newValue in
            // Adjust breathing animation when recording state changes
            withAnimation(.easeInOut(duration: 2.5 * animationSpeed).repeatForever(autoreverses: true)) {
                innerBreathingScale = newValue ? 0.97 : 0.95
            }
        }
    }
}

// Circular record button similar to Eight Sleep's design
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void
    var progress: Double = 1.0 // Default to 1.0 (full circle), when recording this will be countdown progress
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // Animated water gradient background with constant perimeter
                WaterGradientView(animationSpeed: 1.2, isRecording: isRecording)
                    .frame(width: 160, height: 160)
                    // Add subtle bloom effect
                    .shadow(color: Color(hex: isRecording ? "3B82F6" : "4F46E5").opacity(0.7), radius: 25, x: 0, y: 0)
                
                // When recording, add a white circle trim that shows the countdown timer
                if isRecording {
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: 150, height: 150)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.linear(duration: 0.1), value: progress)
                }
                
                // Glass-like overlay to enhance water effect
                Circle()
                    .fill(Color(hex: isRecording ? "3B82F6" : "7668EC").opacity(0.15))
                    .frame(width: 160, height: 160)
                
                // Microphone icon - white for both states with subtle pulsing when recording
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)
            }
            .frame(width: 160, height: 160)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Dark card view in Eight Sleep style
struct DarkCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background(AppColors.cardBackground)
            .cornerRadius(16)
    }
}

// Audio waveform visualization similar to Eight Sleep's minimal UI
struct AudioWaveform: View {
    var level: Double
    @State private var animationPhase: Double = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<20, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "7668EC"),  // Purple
                                Color(hex: "3B82F6")   // Blue
                            ]),
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 3, height: getBarHeight(for: index))
                    .animation(
                        Animation.spring(response: 0.12, dampingFraction: 0.45)
                            .delay(Double(index) * 0.02),
                        value: level
                    )
            }
        }
        .frame(height: 60)  // Keeping the same overall height
        .onAppear {
            // Start continuous animation with faster cycle
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                animationPhase = 1.0
            }
        }
    }
    
    // Calculate dynamic bar height based on index and animation
    private func getBarHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 2  // Lower minimum height to create more contrast
        
        // Only apply significant height if there's audio level
        if level < 0.05 {
            return baseHeight + CGFloat.random(in: 0...2)  // Tiny movement when silent
        }
        
        // Create a natural waveform pattern with multiple sine waves of different frequencies
        let position = Double(index) / 20.0
        
        // More extreme wave function for greater peaks
        let wave1 = sin(position * 10 + animationPhase * 2.5 * .pi + Double(index) * 0.3)
        let wave2 = sin(position * 18 + animationPhase * 4.0 * .pi) * 0.7
        let wave3 = sin(position * 5 + animationPhase * 1.5 * .pi) * 0.5
        
        // Apply more extreme random variation to certain bars
        let randomAmplifier = index % 4 == 0 ? CGFloat.random(in: 1.1...1.8) : 1.0
        
        // Combine waves with higher multiplier
        let combinedWave = (wave1 + wave2 + wave3) / 1.8 // Lower divisor for more extreme values
        let heightMultiplier = baseHeight + (level * 80.0)  // Much more dramatic height difference
        
        // Create more dramatic peaks - now some bars can be almost 2x as tall
        let peakMultiplier: CGFloat
        if Int(position * 20) % 5 == 0 {
            peakMultiplier = 1.8 // Super high peaks
        } else if Int(position * 20) % 3 == 0 {
            peakMultiplier = 1.5 // High peaks
        } else if Int(position * 20) % 2 == 0 {
            peakMultiplier = 0.4 // Very short bars
        } else {
            peakMultiplier = 1.0 // Normal bars
        }
        
        // Apply random variation to height
        let height = max(baseHeight, abs(CGFloat(combinedWave) * heightMultiplier * peakMultiplier * randomAmplifier))
        
        // Apply a subtle random variation to final height
        return height * CGFloat.random(in: 0.9...1.1)
    }
}

// Timer display in Eight Sleep style
struct TimerDisplay: View {
    var seconds: Int
    
    var body: some View {
        Text("\(seconds)s")
            .font(.system(size: 16, weight: .medium, design: .monospaced))
            .foregroundColor(AppColors.textSecondary)
    }
}

// Progress indicator similar to Eight Sleep's minimal UI
struct CircularProgressView: View {
    var progress: Double // 0.0 to 1.0
    var size: CGFloat = 150
    var lineWidth: CGFloat = 4
    
    var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(lineWidth: lineWidth)
                .opacity(0.2)
                .foregroundColor(AppColors.textTertiary)
            
            // Progress indicator
            Circle()
                .trim(from: 0.0, to: CGFloat(min(progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(AppColors.accent)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear(duration: 0.1), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// Measurement style text as seen in Eight Sleep
struct MeasurementText: View {
    var value: Int
    
    var body: some View {
        Text(value < 0 ? "\(value)" : "+\(value)")
            .measurementStyle()
            .foregroundColor(value < 0 ? AppColors.measurementNegative : AppColors.measurementPositive)
    }
}

// Subtle divider in Eight Sleep style
struct DarkDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColors.textTertiary.opacity(0.3))
            .frame(height: 0.5)
            .padding(.vertical, 4)
    }
} 