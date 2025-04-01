//
//  ContentView.swift
//  DailyMinute
//
//  Created by Juliana Crispo on 3/24/25.
//

import SwiftUI
import Speech

struct ContentView: View {
    @Bindable var viewModel: JournalViewModel
    @State private var showSuccessAnimation = false
    @State private var showWaveform = false
    @State private var showTranscription = false
    @Binding var selectedTab: Int  // Add binding to control the selected tab
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Title area - more minimal, similar to Eight Sleep
                    Text("Record")
                        .titleStyle()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 20)
                        .padding(.horizontal)
                    
                    if viewModel.transcriptionInProgress {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.2)
                                .tint(AppColors.accent)
                                .padding()
                            
                            Text("Saving minute...")
                                .headerStyle()
                        }
                        .padding(.vertical, 40)
                    } else if showSuccessAnimation {
                        // Success animation
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.cardBackground)
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .resizable()
                                    .frame(width: 60, height: 60)
                                    .foregroundColor(AppColors.accent)
                            }
                            
                            Text("Minute saved!")
                                .headerStyle()
                        }
                        .padding(.vertical, 40)
                        .transition(.opacity)
                        .onAppear {
                            // Provide haptic feedback
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        }
                    } else {
                        VStack(spacing: 0) {
                            // Main recording area with flexible space for animations
                            Spacer()
                                .frame(height: viewModel.isRecording ? 20 : 100)
                                .animation(.easeInOut(duration: 0.5), value: viewModel.isRecording)
                            
                            // Record button - will float up when recording
                            RecordButton(
                                isRecording: viewModel.isRecording,
                                progress: viewModel.isRecording ? viewModel.timeRemaining / 60.0 : 1.0
                            ) {
                                if viewModel.isRecording {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        showWaveform = false
                                        showTranscription = false
                                    }
                                    
                                    // Small delay before stopping to let animations complete
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        viewModel.stopTranscription()
                                    }
                                } else {
                                    // Reset states BEFORE starting transcription
                                    showWaveform = false
                                    showTranscription = false
                                    
                                    viewModel.startTranscription(mode: .recording) { text in
                                        // Show waveform immediately when recording starts
                                        if !showWaveform {
                                            withAnimation(.easeInOut(duration: 0.6)) {
                                                showWaveform = true
                                            }
                                        }
                                        
                                        // Show transcription with a slight delay when text appears
                                        if !showTranscription && !text.isEmpty {
                                            withAnimation(.easeInOut(duration: 0.6)) {
                                                showTranscription = true
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.bottom, viewModel.isRecording ? 10 : 40)
                            .animation(.easeInOut(duration: 0.5), value: viewModel.isRecording)
                            
                            // Timer text and waveform
                            if viewModel.isRecording && showWaveform {
                                VStack(spacing: 12) {
                                    AudioWaveform(level: viewModel.audioLevel)
                                        .padding(.horizontal)
                                    
                                    TimerDisplay(seconds: Int(viewModel.timeRemaining))
                                }
                                .padding(.bottom, 20)
                                .frame(maxHeight: 100)
                                .clipped()
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            // Transcribed text area - no dark card, just clean text
                            if viewModel.isRecording && showTranscription && !viewModel.currentText.isEmpty {
                                ScrollView {
                                    Text(viewModel.currentText)
                                        .bodyStyle()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                }
                                .frame(maxHeight: 200)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                                .animation(.easeInOut(duration: 0.7), value: viewModel.currentText)
                            } else if !viewModel.isRecording && !viewModel.currentText.isEmpty {
                                // Show full transcription when not recording
                                ScrollView {
                                    Text(viewModel.currentText)
                                        .bodyStyle()
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 20)
                                }
                                .frame(maxHeight: .infinity)
                                .transition(.opacity)
                                .animation(.easeInOut(duration: 0.5), value: viewModel.isRecording)
                            }
                            
                            Spacer(minLength: viewModel.isRecording ? 40 : 100)
                                .animation(.easeInOut(duration: 0.5), value: viewModel.isRecording)
                        }
                        .animation(.easeInOut(duration: 0.5), value: viewModel.isRecording)
                    }
                    
                    Spacer()
                    
                    // Bottom info in Eight Sleep style
                    if !viewModel.isRecording && !viewModel.currentText.isEmpty {
                        DarkCard {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Off")
                                        .headerStyle()
                                    Text("Turns on when recording starts")
                                        .captionStyle()
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    // Toggle autopilot state (placeholder)
                                }) {
                                    Text("Autopilot is off")
                                        .captionStyle()
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(AppColors.cardBackgroundSecondary)
                                        .cornerRadius(20)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.5), value: viewModel.isRecording)
                    }
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                viewModel.requestSpeechAuthorization()
            }
            .onChange(of: viewModel.entrySaved) { newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSuccessAnimation = true
                    }
                    
                    // Switch to the Minutes tab immediately after showing success
                    // but before the success animation completes
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        selectedTab = 1  // Switch to Minutes tab before success animation completes
                        
                        // Reset success animation state after tab switch
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showSuccessAnimation = false
                        }
                    }
                }
            }
            .onChange(of: viewModel.isRecording) { isRecording in
                // Reset UI state when recording stops
                if !isRecording {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showWaveform = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark) // Force dark mode
    }
}

#Preview {
    ContentView(viewModel: JournalViewModel(), selectedTab: .constant(0))
}
