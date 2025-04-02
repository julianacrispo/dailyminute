import SwiftUI
import AVFoundation

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
    private let maxBarHeight: CGFloat = 50  // Maximum height constraint for bars
    private let containerHeight: CGFloat = 60  // Fixed container height
    
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
        .frame(height: containerHeight)  // Fixed container height
        .clipShape(Rectangle())  // Ensure visualization stays within this container
    }
    
    // Calculate dynamic bar height based on index and audio level
    private func getBarHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 2  // Minimum height when silent
        
        // When silent or very low audio, just show flat line with minimal height
        if level < 0.03 {
            return baseHeight
        }
        
        // Create a natural distribution pattern for the bars
        // Center bars are taller, edges are shorter
        let position = Double(index) / 19.0  // Normalize position (0 to 1)
        let positionFactor = 1.0 - abs((position * 2.0) - 1.0)  // Highest in middle (0->1->0)
        
        // Calculate frequency-like distribution - we simulate different frequencies
        // by using the bar index to determine its behavior
        let frequencyFactor: Double
        if index % 4 == 0 {
            // Low frequency bars - slower but can be taller
            frequencyFactor = 1.2
        } else if index % 2 == 0 {
            // Mid frequency bars
            frequencyFactor = 1.0
        } else {
            // High frequency bars - shorter
            frequencyFactor = 0.7
        }
        
        // Apply a non-linear scale to make the waveform more sensitive to volume changes
        // This will create more distinction between soft, medium, and loud speech
        let volumeScale = pow(level, 1.5) // Apply exponential scaling to accentuate differences
        
        // Calculate the height based on audio level and position with improved scaling
        // Reduced the multiplier to prevent bars from hitting max height too easily
        let heightMultiplier = baseHeight + (volumeScale * 70.0 * positionFactor * frequencyFactor)
        
        // Add a very small amount of randomness to make it feel organic
        // but not so much that it looks jittery
        let organicFactor = CGFloat.random(in: 0.96...1.04)
        
        // Apply maximum height constraint
        return min(heightMultiplier * organicFactor, maxBarHeight)
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

// Audio Player View for playback of recorded minutes
struct AudioPlayerView: View {
    var audioURL: URL
    @State private var isPlaying: Bool = false
    @State private var progress: Double = 0.0
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var playbackRate: Float = 1.0
    
    // We'll use this to track the audio player
    @State private var audioPlayer: AVAudioPlayer?
    
    // Timer to update progress during playback
    @State private var progressTimer: Timer?
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            HStack(spacing: 8) {
                Text(formatTime(currentTime))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)
                
                Slider(value: $progress, in: 0...1)
                    .accentColor(AppColors.accent)
                    .onChange(of: progress) { newValue in
                        // Only seek when user is dragging, not during normal playback
                        if !isPlaying || (audioPlayer?.isPlaying == false) {
                            seekTo(percentage: newValue)
                        }
                    }
                
                Text(formatTime(duration))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(AppColors.textSecondary)
            }
            
            // Playback controls
            HStack(spacing: 20) {
                // Play/Pause button
                Button(action: {
                    togglePlayback()
                }) {
                    Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(AppColors.accent)
                }
                
                // Playback speed options
                HStack(spacing: 8) {
                    Text("Speed:")
                        .captionStyle()
                    
                    ForEach([0.5, 1.0, 1.5, 2.0], id: \.self) { rate in
                        Button(action: {
                            setPlaybackRate(rate: Float(rate))
                        }) {
                            Text("\(rate, specifier: "%.1f")x")
                                .font(.system(size: 12, weight: playbackRate == Float(rate) ? .bold : .regular))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    playbackRate == Float(rate) ?
                                    AppColors.accent.opacity(0.3) :
                                    AppColors.cardBackground.opacity(0.5)
                                )
                                .cornerRadius(12)
                                .foregroundColor(
                                    playbackRate == Float(rate) ?
                                    AppColors.accent :
                                    AppColors.textSecondary
                                )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            setupAudioPlayer()
        }
        .onDisappear {
            stopPlayback()
        }
    }
    
    // Format time for display
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval / 60)
        let seconds = Int(timeInterval.truncatingRemainder(dividingBy: 60))
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    // Initialize the audio player
    private func setupAudioPlayer() {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: audioURL)
            audioPlayer?.prepareToPlay()
            duration = audioPlayer?.duration ?? 0
            
            // Setup audio session for playback
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error setting up audio player: \(error.localizedDescription)")
        }
    }
    
    // Toggle between play and pause
    private func togglePlayback() {
        if isPlaying {
            pausePlayback()
        } else {
            startPlayback()
        }
    }
    
    // Start playing the audio
    private func startPlayback() {
        audioPlayer?.play()
        isPlaying = true
        
        // Start a timer to update progress
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let player = audioPlayer, player.isPlaying {
                currentTime = player.currentTime
                progress = currentTime / duration
                
                // If playback reaches the end, reset
                if currentTime >= duration {
                    isPlaying = false
                    progress = 0
                    currentTime = 0
                    progressTimer?.invalidate()
                }
            }
        }
    }
    
    // Pause the audio
    private func pausePlayback() {
        audioPlayer?.pause()
        isPlaying = false
        progressTimer?.invalidate()
    }
    
    // Stop playback completely
    private func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
        progressTimer?.invalidate()
        audioPlayer = nil
    }
    
    // Seek to a specific position
    private func seekTo(percentage: Double) {
        let targetTime = duration * percentage
        audioPlayer?.currentTime = targetTime
        currentTime = targetTime
    }
    
    // Change playback speed
    private func setPlaybackRate(rate: Float) {
        playbackRate = rate
        audioPlayer?.rate = rate
    }
} 