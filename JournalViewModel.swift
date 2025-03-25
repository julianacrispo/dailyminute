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
    
    private var audioEngine = AVAudioEngine()
    private var speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var timer: Timer?
    
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
        
        // Skip saving if there's no text
        if currentText.isEmpty {
            return
        }
        
        // Store the current text for entry creation
        let textToSave = currentText
        
        // IMPORTANT: Save the entry IMMEDIATELY to ensure it's not lost
        // even if the user navigates away
        let newEntry = JournalEntry(text: textToSave)
        journalEntries.append(newEntry)
        
        // Clear the current text after saving - do this immediately as well
        // to avoid any race conditions
        let savedText = currentText
        currentText = ""
        
        // Show processing state for visual feedback only
        // This is just for UX, but the data is already saved
        transcriptionInProgress = true
        
        // Visual feedback after saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            
            // Reset the UI state
            self.transcriptionInProgress = false
            
            // Signal that entry was saved successfully - only for animation
            self.entrySaved = true
            
            // Reset the saved flag after a delay
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
