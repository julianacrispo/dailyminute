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
        VStack(spacing: 24) {
            Text("Setup Checklist")
                .font(.title2)
                .fontWeight(.semibold)
                .padding(.top, 32)
            
            if isCheckingPermissions {
                ProgressView()
                    .scaleEffect(1.2)
                    .padding()
            } else {
                Text("This will only take a few seconds and you'll be ready to get started.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    PermissionRow(
                        title: "Microphone Access",
                        subtitle: "Required to record your minutes",
                        isAuthorized: $microphoneAuthorized,
                        isLoading: $microphoneLoading,
                        systemImage: "mic",
                        action: requestMicrophoneAccess
                    )
                    
                    PermissionRow(
                        title: "Speech Recognition",
                        subtitle: "Required to transcribe your minutes",
                        isAuthorized: $speechRecognitionAuthorized,
                        isLoading: $speechRecognitionLoading,
                        systemImage: "waveform",
                        action: requestSpeechRecognitionAccess
                    )
                }
                .padding()
            }
            
            Spacer()
            
            Button(action: {
                if microphoneAuthorized && speechRecognitionAuthorized {
                    hasCompletedOnboarding = true
                }
            }) {
                Text("Continue")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        (microphoneAuthorized && speechRecognitionAuthorized) ?
                        Color.black : Color.gray
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .disabled(!(microphoneAuthorized && speechRecognitionAuthorized))
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .padding()
        .onAppear(perform: checkExistingPermissions)
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

struct PermissionRow: View {
    let title: String
    let subtitle: String
    @Binding var isAuthorized: Bool
    @Binding var isLoading: Bool
    let systemImage: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundColor(.black)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Toggle("", isOn: Binding(
                    get: { isAuthorized },
                    set: { newValue in
                        if newValue && !isAuthorized {
                            action()
                        }
                    }
                ))
                .toggleStyle(SwitchToggleStyle(tint: .black))
                .disabled(isAuthorized) // Only allow toggling on, not off
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            if !isAuthorized && !isLoading {
                action()
            }
        }
    }
} 