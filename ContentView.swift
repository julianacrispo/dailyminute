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
    
    var body: some View {
        NavigationView {
            VStack {
                // Title area - centered, "Journal" removed
                Text("Hey Juliana, what are you thinking?")
                    .font(.system(size: 20))
                    .foregroundColor(Color(.systemGray))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                if viewModel.transcriptionInProgress {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                        
                        Text("Saving minute...")
                            .font(.headline)
                            .foregroundColor(Color(.systemGray))
                    }
                    .padding(.vertical)
                } else if showSuccessAnimation {
                    // Success animation
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemGray6))
                                .frame(width: 100, height: 100)
                            
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 70, height: 70)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color.black, Color(.systemGray2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                        
                        Text("Minute saved!")
                            .font(.headline)
                            .foregroundColor(Color(.systemGray))
                    }
                    .padding(.vertical)
                    .transition(.opacity)
                    .onAppear {
                        // Provide haptic feedback
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)
                        
                        // Auto-dismiss the success animation after a delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeOut(duration: 0.3)) {
                                showSuccessAnimation = false
                            }
                        }
                    }
                } else {
                    // Recording area - always visible at top when not recording
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 4)
                            .opacity(0.2)
                            .foregroundColor(Color(.systemGray3))
                        
                        Circle()
                            .trim(from: 0.0, to: viewModel.isRecording ? max(0, min(1, CGFloat(viewModel.timeRemaining / 60.0))) : 1.0)
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color(.systemGray))
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear(duration: 0.1), value: viewModel.timeRemaining)
                        
                        Button(action: {
                            if viewModel.isRecording {
                                viewModel.stopTranscription()
                            } else {
                                viewModel.startTranscription(mode: .recording) { text in
                                    // Text updates will be handled by the ViewModel
                                }
                            }
                        }) {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundStyle(
                                    viewModel.isRecording ?
                                    LinearGradient(
                                        colors: [Color(.systemGray), Color(.systemGray2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ) :
                                    LinearGradient(
                                        colors: [Color.black, Color(.systemGray2)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        }
                    }
                    .frame(width: 150, height: 150)
                    
                    // Timer text - shows during recording
                    if viewModel.isRecording {
                        VStack(spacing: 10) {
                            // Dynamic waveform visualization
                            HStack(spacing: 3) {
                                ForEach(0..<20) { index in
                                    RoundedRectangle(cornerRadius: 1)
                                        .fill(Color(.systemGray))
                                        .frame(width: 2, height: 20)
                                        .scaleEffect(
                                            y: 0.1 + (viewModel.audioLevel * 
                                                (sin(Double(index) / 2 + Date().timeIntervalSince1970 * 5) * 0.5 +
                                                cos(Double(index) / 3 + Date().timeIntervalSince1970 * 4) * 0.3 +
                                                sin(Double(index) + Date().timeIntervalSince1970 * 6) * 0.2) * 
                                                (viewModel.audioLevel > 0.1 ? 1.0 : 0.2)
                                            ),
                                            anchor: .center
                                        )
                                        .animation(
                                            Animation.spring(response: 0.1, dampingFraction: 0.7)
                                                .delay(Double(index) * 0.01),
                                            value: viewModel.audioLevel
                                        )
                                }
                            }
                            .frame(height: 25)
                            
                            Text("\(Int(viewModel.timeRemaining))s")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.systemGray))
                        }
                        .padding(.bottom, 10)
                    }
                    
                    // Transcribed text area
                    if !viewModel.currentText.isEmpty {
                        ScrollView {
                            Text(viewModel.currentText)
                                .foregroundColor(Color(.systemGray))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: viewModel.isRecording ? 200 : .infinity)
                    } else if !viewModel.isRecording {
                        // Remove instruction text completely
                        Spacer()
                    }
                }
                
                Spacer()
            }
            // Remove the title from the navigation bar since we have our own centered title
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.requestSpeechAuthorization()
            }
            .onChange(of: viewModel.entrySaved) { newValue in
                if newValue {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showSuccessAnimation = true
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView(viewModel: JournalViewModel())
}
