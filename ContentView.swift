//
//  ContentView.swift
//  DailyMinute
//
//  Created by Juliana Crispo on 3/24/25.
//

import SwiftUI
import Speech

struct ContentView: View {
    @ObservedObject var viewModel: JournalViewModel
    
    var body: some View {
        NavigationView {
            VStack {
                // Title area - centered, "Journal" removed
                Text("Daily Minute")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                
                if viewModel.transcriptionInProgress {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                        
                        Text("Saving entry...")
                            .font(.headline)
                    }
                    .padding(.vertical)
                } else {
                    // Recording area - always visible at top when not recording
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 5)
                            .opacity(0.3)
                            .foregroundColor(Color.blue)
                        
                        Circle()
                            .trim(from: 0.0, to: viewModel.isRecording ? CGFloat(viewModel.timeRemaining / 60.0) : 1.0)
                            .stroke(style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                            .foregroundColor(Color.blue)
                            .rotationEffect(Angle(degrees: 270.0))
                            .animation(.linear, value: viewModel.timeRemaining)
                        
                        Button(action: {
                            if viewModel.isRecording {
                                viewModel.stopRecording()
                            } else {
                                viewModel.startRecording()
                            }
                        }) {
                            Image(systemName: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundColor(viewModel.isRecording ? .red : .blue)
                        }
                    }
                    .frame(width: 150, height: 150)
                    
                    // Timer text - shows during recording
                    if viewModel.isRecording {
                        Text("Recording: \(Int(viewModel.timeRemaining)) seconds left")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding(.bottom, 10)
                    }
                    
                    // Transcribed text area
                    if !viewModel.currentText.isEmpty {
                        ScrollView {
                            Text(viewModel.currentText)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                        .padding(.horizontal)
                        .frame(maxHeight: viewModel.isRecording ? 200 : .infinity)
                    } else if !viewModel.isRecording {
                        // Instruction text when idle
                        Text("Tap the microphone to start recording (max 1 minute)")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
                
                Spacer()
            }
            // Remove the title from the navigation bar since we have our own centered title
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                viewModel.requestSpeechAuthorization()
            }
        }
    }
}

#Preview {
    ContentView(viewModel: JournalViewModel())
}
