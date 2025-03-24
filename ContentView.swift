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
    @State private var editMode = false
    
    var body: some View {
        NavigationView {
            VStack {
                if viewModel.transcriptionInProgress {
                    ProgressView("Processing your journal entry...")
                        .padding()
                } else if !viewModel.currentText.isEmpty || editMode {
                    VStack {
                        if editMode {
                            TextEditor(text: $viewModel.currentText)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                                .padding()
                        } else {
                            ScrollView {
                                Text(viewModel.currentText)
                                    .padding()
                            }
                        }
                        
                        HStack {
                            Button(action: {
                                editMode.toggle()
                            }) {
                                Text(editMode ? "Done Editing" : "Edit")
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                            
                            Button(action: {
                                viewModel.saveEntry()
                                editMode = false
                            }) {
                                Text("Save Entry")
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }
                        .padding()
                    }
                } else {
                    Spacer()
                    
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
                                .frame(width: 100, height: 100)
                                .foregroundColor(viewModel.isRecording ? .red : .blue)
                        }
                    }
                    .frame(width: 200, height: 200)
                    
                    Spacer()
                    
                    if viewModel.isRecording {
                        Text("Recording: \(Int(viewModel.timeRemaining)) seconds left")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                    } else {
                        Text("Tap the microphone to start recording (max 1 minute)")
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                }
            }
            .navigationTitle("Daily Minute Journal")
            .onAppear {
                viewModel.requestSpeechAuthorization()
            }
        }
    }
}

#Preview {
    ContentView(viewModel: JournalViewModel())
}
