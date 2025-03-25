import Foundation
import Speech
import SwiftUI

class JournalViewModel: ObservableObject {
    @Published var journalEntries: [JournalEntry] = []
    @Published var currentText: String = ""
    @Published var isRecording: Bool = false
    @Published var timeRemaining: Double = 60.0
    @Published var transcriptionInProgress: Bool = false
    @Published var entrySaved: Bool = false
    @Published var audioLevel: Double = 0.0
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?
    private var audioLevelTimer: Timer?
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            DispatchQueue.main.async {
                if authStatus != .authorized {
                    // Handle unauthorized access
                    print("Speech recognition not authorized")
                }
            }
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        // Reset the timer and text
        timeRemaining = 60.0
        currentText = ""
        
        // Start the recognition process
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let recognitionRequest = recognitionRequest else { return }
        
        let inputNode = audioEngine.inputNode
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            if let result = result {
                self.currentText = result.bestTranscription.formattedString
            }
            
            if error != nil || (result?.isFinal ?? false) {
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
            
            // Calculate audio level from buffer
            let channelData = buffer.floatChannelData?[0]
            if let channelData = channelData {
                let frames = buffer.frameLength
                var sum: Float = 0
                for i in 0..<frames {
                    sum += abs(channelData[Int(i)])
                }
                let avg = sum / Float(frames)
                DispatchQueue.main.async {
                    // Add noise threshold and make the response more dramatic
                    let threshold: Float = 0.01  // Adjust this value to change sensitivity
                    let normalizedLevel = avg * 15  // Amplify the signal
                    if normalizedLevel < threshold {
                        // If below threshold, quickly decrease to show silence
                        self.audioLevel = max(0, self.audioLevel - 0.3)
                    } else {
                        // If above threshold, use the normalized level
                        self.audioLevel = Double(min(max(normalizedLevel, 0), 1))
                    }
                }
            }
        }
        
        do {
            try audioEngine.start()
            isRecording = true
            startTimer()
        } catch {
            print("Audio engine failed to start: \(error.localizedDescription)")
        }
    }
    
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        
        isRecording = false
        stopTimer()
        audioLevel = 0.0
        
        // Skip saving if there's no text
        if currentText.isEmpty {
            return
        }
        
        // Store the current text for entry creation
        let textToSave = currentText
        
        // Save the entry IMMEDIATELY
        let newEntry = JournalEntry(text: textToSave)
        journalEntries.append(newEntry)
        
        // Clear the current text after saving
        let savedText = currentText
        currentText = ""
        
        // Show processing state
        transcriptionInProgress = true
        
        // Visual feedback after saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            self.transcriptionInProgress = false
            self.entrySaved = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.entrySaved = false
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.timeRemaining -= 0.1
            
            if self.timeRemaining <= 0 {
                self.stopRecording()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    // Keep only the original saveEntry method for backward compatibility
    func saveEntry() {
        let newEntry = JournalEntry(text: currentText)
        journalEntries.append(newEntry)
        currentText = ""
    }
    
    func updateEntry(id: UUID, newText: String) {
        if let index = journalEntries.firstIndex(where: { $0.id == id }) {
            // Create a new entry with updated text but same ID and date
            var updatedEntry = journalEntries[index]
            updatedEntry.text = newText
            
            // Replace the old entry with the updated one
            journalEntries[index] = updatedEntry
        }
    }
} 
