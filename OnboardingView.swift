import SwiftUI
import AVFoundation
import Speech

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    @State private var microphoneAuthorized = false
    @State private var speechRecognitionAuthorized = false
    @State private var isCheckingPermissions = false
    @State private var microphoneLoading = false
    @State private var speechRecognitionLoading = false
    
    // Pre-warm permissions on view appear
    private func checkExistingPermissions() {
        isCheckingPermissions = true
        
        // Check microphone status
        switch AVAudioSession.sharedInstance().recordPermission {
        case .granted:
            microphoneAuthorized = true
        case .denied:
            microphoneAuthorized = false
        case .undetermined:
            break
        @unknown default:
            break
        }
        
        // Check speech recognition status
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            speechRecognitionAuthorized = true
        case .denied, .restricted:
            speechRecognitionAuthorized = false
        case .notDetermined:
            break
        @unknown default:
            break
        }
        
        isCheckingPermissions = false
    }
    
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Title area
                Text("DailyMinute")
                    .titleStyle()
                    .padding(.top, 60)
                
                if isCheckingPermissions {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(AppColors.accent)
                        .padding()
                    Spacer()
                } else {
                    Text("Setup Required")
                        .headerStyle()
                        .padding(.bottom, 10)
                    
                    Text("Please enable the following permissions to use voice recording features.")
                        .captionStyle()
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)
                    
                    // Permission cards in Eight Sleep style
                    DarkCard {
                        VStack(spacing: 20) {
                            PermissionRowDark(
                                title: "Microphone Access",
                                subtitle: "Required to record your minutes",
                                isAuthorized: $microphoneAuthorized,
                                isLoading: $microphoneLoading,
                                systemImage: "mic.fill",
                                action: requestMicrophoneAccess
                            )
                            
                            DarkDivider()
                            
                            PermissionRowDark(
                                title: "Speech Recognition",
                                subtitle: "Required to transcribe your minutes",
                                isAuthorized: $speechRecognitionAuthorized,
                                isLoading: $speechRecognitionLoading,
                                systemImage: "waveform",
                                action: requestSpeechRecognitionAccess
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Continue button in Eight Sleep style
                    Button(action: {
                        if microphoneAuthorized && speechRecognitionAuthorized {
                            hasCompletedOnboarding = true
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (microphoneAuthorized && speechRecognitionAuthorized) ?
                                AppColors.accent : AppColors.textTertiary
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(!(microphoneAuthorized && speechRecognitionAuthorized))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarHidden(true)
        }
        .onAppear(perform: checkExistingPermissions)
        .preferredColorScheme(.dark)
    }
    
    private func requestMicrophoneAccess() {
        guard !microphoneLoading else { return }
        microphoneLoading = true
        
        // Ensure we're on the main thread when requesting authorization
        DispatchQueue.main.async {
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    microphoneAuthorized = granted
                    microphoneLoading = false
                }
            }
        }
    }
    
    private func requestSpeechRecognitionAccess() {
        guard !speechRecognitionLoading else { return }
        speechRecognitionLoading = true
        
        // Ensure we're on the main thread when requesting authorization
        DispatchQueue.main.async {
            SFSpeechRecognizer.requestAuthorization { status in
                DispatchQueue.main.async {
                    speechRecognitionAuthorized = (status == .authorized)
                    speechRecognitionLoading = false
                }
            }
        }
    }
}

// Dark themed permission row for Eight Sleep style
struct PermissionRowDark: View {
    let title: String
    let subtitle: String
    @Binding var isAuthorized: Bool
    @Binding var isLoading: Bool
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 22))
                .foregroundColor(isAuthorized ? AppColors.accent : AppColors.textPrimary)
                .frame(width: 32)
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .headerStyle()
                
                Text(subtitle)
                    .captionStyle()
            }
            
            Spacer()
            
            // Toggle or loading indicator
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(AppColors.accent)
            } else {
                Toggle("", isOn: Binding(
                    get: { isAuthorized },
                    set: { newValue in
                        if newValue && !isAuthorized {
                            action()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: AppColors.accent))
                .disabled(isAuthorized) // Only allow toggling on, not off
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if !isAuthorized && !isLoading {
                action()
            }
        }
    }
} 